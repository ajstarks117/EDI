import { useRef, useCallback } from 'react';
import { useVirtualizer } from '@tanstack/react-virtual';
import { useAlertStore, type Alert } from '../store/useAlertStore';
import { ShieldAlert, AlertTriangle, Info, AlertOctagon, CheckCircle, Volume2, ArrowRightCircle, User, FileText } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { useNavigate } from 'react-router-dom';
import { useRBAC } from '../hooks/useRBAC';
import IncidentReportModal from '../components/IncidentReportModal';
import { SkeletonRow } from '../components/Skeleton';
import EmptyState from '../components/EmptyState';
import { useState } from 'react';

const PriorityIcon = ({ priority }: { priority: Alert['priority'] }) => {
  switch (priority) {
    case 'P0': return <ShieldAlert className="h-6 w-6 text-rose-500" />;
    case 'P1': return <AlertOctagon className="h-6 w-6 text-orange-500" />;
    case 'P2': return <AlertTriangle className="h-6 w-6 text-amber-500" />;
    case 'P3': return <AlertTriangle className="h-6 w-6 text-yellow-400" />;
    case 'P4': return <Info className="h-6 w-6 text-indigo-400" />;
  }
};

const PriorityLabel = ({ priority }: { priority: Alert['priority'] }) => {
  switch (priority) {
    case 'P0': return <span className="bg-rose-500/10 text-rose-400 border border-rose-500/20 px-2 py-0.5 rounded text-xs font-bold uppercase tracking-wider">P0 SOS</span>;
    case 'P1': return <span className="bg-orange-500/10 text-orange-400 border border-orange-500/20 px-2 py-0.5 rounded text-xs font-bold uppercase tracking-wider">P1 Exclusion</span>;
    case 'P2': return <span className="bg-amber-500/10 text-amber-400 border border-amber-500/20 px-2 py-0.5 rounded text-xs font-bold uppercase tracking-wider">P2 Restricted</span>;
    case 'P3': return <span className="bg-yellow-400/10 text-yellow-400 border border-yellow-400/20 px-2 py-0.5 rounded text-xs font-bold uppercase tracking-wider">P3 Weather</span>;
    case 'P4': return <span className="bg-indigo-400/10 text-indigo-400 border border-indigo-400/20 px-2 py-0.5 rounded text-xs font-bold uppercase tracking-wider">P4 Info</span>;
  }
};

export default function Alerts() {
  const { alertFeed, isLoading, error, updateAlert, addAlert, initializeData } = useAlertStore();
  const navigate = useNavigate();
  const { canManageAlerts } = useRBAC();
  const [selectedReportAlert, setSelectedReportAlert] = useState<Alert | null>(null);

  const parentRef = useRef<HTMLDivElement>(null);

  const rowVirtualizer = useVirtualizer({
    count: alertFeed.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 100, // estimated height per row
    overscan: 10,
  });

  const handleAction = useCallback((id: string, newStatus: Alert['status']) => {
    updateAlert(id, { status: newStatus });
  }, [updateAlert]);

  const testAlerts = () => {
    // Play synthetic distinct tone
    try {
      const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = audioCtx.createOscillator();
      const gainNode = audioCtx.createGain();
      
      oscillator.type = 'square';
      oscillator.frequency.setValueAtTime(880, audioCtx.currentTime); // A5 beep
      oscillator.frequency.exponentialRampToValueAtTime(440, audioCtx.currentTime + 0.2);
      
      gainNode.gain.setValueAtTime(1, audioCtx.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.5);
      
      oscillator.connect(gainNode);
      gainNode.connect(audioCtx.destination);
      
      oscillator.start();
      oscillator.stop(audioCtx.currentTime + 0.5);
    } catch (e) {
      alert('Audio play blocked: ' + (e as Error).message);
    }

    if (typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'granted') {
      new Notification('⚠️ P0 SOS ALERT', {
        body: 'TEST: Audio and Notification permission check',
        requireInteraction: true,
      });
    } else if (typeof window !== 'undefined' && 'Notification' in window && Notification.permission !== 'granted') {
      alert('Notification permission not granted. Please enable via the banner.');
    }
    
    addAlert({
      priority: 'P0',
      message: 'TEST: Audio permission check and SOS mock',
    });
  };

  const handleViewTourist = (touristId?: string) => {
    if (!touristId) return;
    // For now navigate to map, in full implementation we set flyToLocation and selectedTourist
    navigate('/map');
  };

  return (
    <div className="flex flex-col h-[calc(100vh-8rem)]">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold font-outfit text-dark-text">Priority Alert Feed</h1>
          <p className="text-muted-text text-sm">Real-time threat matrix and operational queue</p>
        </div>
        <div className="flex items-center space-x-4">
          <div className="bg-surface-card border border-surface-border px-4 py-2 rounded-lg flex items-center space-x-2">
            <div className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
            <span className="text-sm font-medium">Queue Active: {alertFeed.length}</span>
          </div>
          <button 
            onClick={testAlerts}
            className="flex items-center space-x-2 bg-indigo-600/20 text-indigo-400 hover:bg-indigo-600/30 border border-indigo-500/30 px-4 py-2 rounded-lg font-medium transition"
          >
            <Volume2 className="h-4 w-4" />
            <span>Test Audio & Notifications</span>
          </button>
        </div>
      </div>

      <div 
        ref={parentRef} 
        className="flex-1 overflow-auto rounded-xl border border-surface-border bg-surface-card/40 backdrop-blur"
      >
        {isLoading ? (
          <div className="p-4 space-y-4">
            <SkeletonRow />
            <SkeletonRow />
            <SkeletonRow />
            <SkeletonRow />
            <SkeletonRow />
          </div>
        ) : error ? (
          <div className="flex flex-col items-center justify-center h-full p-8 text-center text-rose-400">
            <AlertTriangle className="h-12 w-12 mb-4 opacity-50" />
            <p className="font-semibold">Failed to load alerts</p>
            <p className="text-sm opacity-80 mb-4">{error}</p>
            <button onClick={initializeData} className="px-4 py-2 bg-rose-500/10 hover:bg-rose-500/20 rounded transition text-sm">Retry</button>
          </div>
        ) : alertFeed.length === 0 ? (
          <EmptyState 
            icon={CheckCircle}
            title="All Clear"
            description="There are currently no active alerts or incidents in the queue. Everything is operating normally."
          />
        ) : (
          <div
            style={{
              height: `${rowVirtualizer.getTotalSize()}px`,
              width: '100%',
              position: 'relative',
            }}
          >
          {rowVirtualizer.getVirtualItems().map((virtualRow) => {
            const alert = alertFeed[virtualRow.index];
            const isRead = alert.status === 'closed' || alert.status === 'acknowledged';

            return (
              <div
                key={virtualRow.key}
                style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  width: '100%',
                  height: `${virtualRow.size}px`,
                  transform: `translateY(${virtualRow.start}px)`,
                }}
                className={`flex items-center justify-between w-full p-4 border-b border-surface-border transition cursor-default group focus:outline-none focus:ring-inset focus:ring-2 focus:ring-indigo-500 focus:z-10 hover:bg-surface-card
                  ${!isRead ? 'bg-surface-card/60' : 'bg-transparent opacity-60'}
                `}
                tabIndex={0}
                role="group"
                aria-label={`${alert.priority} alert: ${alert.message}`}
              >
                <div className="flex items-center justify-between w-full">
                  <div className="flex items-center space-x-4 flex-1">
                    <div className={`p-2 rounded-lg ${alert.priority === 'P0' ? 'bg-rose-500/10' : 'bg-surface-bg'}`}>
                      <PriorityIcon priority={alert.priority} />
                    </div>
                    <div className="flex flex-col">
                      <div className="flex items-center space-x-3">
                        <PriorityLabel priority={alert.priority} />
                        <span className="text-xs text-slate-400">
                          {formatDistanceToNow(alert.timestamp, { addSuffix: true })}
                        </span>
                        <span className="text-xs font-semibold text-slate-500 uppercase">
                          Status: {alert.status}
                        </span>
                      </div>
                      <p className={`mt-1 font-medium ${alert.priority === 'P0' ? 'text-rose-100 font-bold' : 'text-slate-200'}`}>
                        {alert.message}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    {alert.status === 'new' && (
                      <button 
                        onClick={() => handleAction(alert.id, 'acknowledged')}
                        disabled={!canManageAlerts()}
                        title={!canManageAlerts() ? "Restricted: Requires Admin or Dispatcher role" : "Acknowledge"}
                        className="px-3 py-1.5 text-xs font-semibold rounded bg-indigo-600 hover:bg-indigo-700 text-white transition disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        Acknowledge
                      </button>
                    )}
                    {(alert.status === 'new' || alert.status === 'acknowledged') && (
                      <button 
                        onClick={() => handleAction(alert.id, 'assigned')}
                        disabled={!canManageAlerts()}
                        title={!canManageAlerts() ? "Restricted: Requires Admin or Dispatcher role" : "Assign"}
                        className="px-3 py-1.5 text-xs font-semibold rounded bg-surface-bg hover:bg-surface-border border border-surface-border text-slate-300 transition disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        Assign
                      </button>
                    )}
                    {alert.touristId && (
                      <button 
                        onClick={() => handleViewTourist(alert.touristId)}
                        className="flex items-center space-x-1 px-3 py-1.5 text-xs font-semibold rounded bg-surface-bg hover:bg-surface-border border border-surface-border text-slate-300 transition"
                      >
                        <User className="h-3.5 w-3.5" />
                        <span>View</span>
                      </button>
                    )}
                    {alert.status !== 'escalated' && alert.status !== 'closed' && (
                      <button 
                        onClick={() => handleAction(alert.id, 'escalated')}
                        disabled={!canManageAlerts()}
                        title={!canManageAlerts() ? "Restricted: Requires Admin or Dispatcher role" : "Escalate"}
                        className="flex items-center space-x-1 px-3 py-1.5 text-xs font-semibold rounded bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/20 text-rose-400 transition disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <ArrowRightCircle className="h-3.5 w-3.5" />
                        <span>Escalate</span>
                      </button>
                    )}
                    {alert.status !== 'closed' && (
                      <button 
                        onClick={() => handleAction(alert.id, 'closed')}
                        disabled={!canManageAlerts()}
                        title={!canManageAlerts() ? "Restricted: Requires Admin or Dispatcher role" : "Close"}
                        className="flex items-center space-x-1 px-3 py-1.5 text-xs font-semibold rounded bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/20 text-emerald-400 transition disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <CheckCircle className="h-3.5 w-3.5" />
                        <span>Close</span>
                      </button>
                    )}
                    {alert.status === 'closed' && (
                      <button 
                        onClick={() => setSelectedReportAlert(alert)}
                        className="flex items-center space-x-1 px-3 py-1.5 text-xs font-semibold rounded bg-slate-500/10 hover:bg-slate-500/20 border border-slate-500/20 text-slate-300 transition"
                      >
                        <FileText className="h-3.5 w-3.5" />
                        <span>View Report</span>
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
        )}
      </div>
      
      {selectedReportAlert && (
        <IncidentReportModal 
          alert={selectedReportAlert} 
          onClose={() => setSelectedReportAlert(null)} 
        />
      )}
    </div>
  );
}
