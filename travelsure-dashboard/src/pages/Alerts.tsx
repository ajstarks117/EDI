import { useRef, useCallback } from 'react';
import { useVirtualizer } from '@tanstack/react-virtual';
import { useAlertStore, type Alert } from '../store/useAlertStore';
import { ShieldAlert, AlertTriangle, Info, AlertOctagon, CheckCircle, Volume2, ArrowRightCircle, User } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { useNavigate } from 'react-router-dom';

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
  const { alertFeed, updateAlert, addAlert } = useAlertStore();
  const navigate = useNavigate();

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

  const testAudio = () => {
    // Generate a test P0 alert to verify audio and insert it to queue
    const audio = new Audio('/sos-alert.mp3'); // Requires actual file in public, but tests permission
    audio.play().catch(e => alert('Audio play blocked: ' + e.message));
    
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
            onClick={testAudio}
            className="flex items-center space-x-2 bg-indigo-600/20 text-indigo-400 hover:bg-indigo-600/30 border border-indigo-500/30 px-4 py-2 rounded-lg font-medium transition"
          >
            <Volume2 className="h-4 w-4" />
            <span>Enable Audio</span>
          </button>
        </div>
      </div>

      <div 
        ref={parentRef} 
        className="flex-1 overflow-auto rounded-xl border border-surface-border bg-surface-card/40 backdrop-blur"
      >
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
                className={`border-b border-surface-border p-4 flex flex-col justify-center transition-colors ${
                  !isRead ? 'bg-surface-card/60' : 'bg-transparent opacity-60'
                } hover:bg-surface-bg`}
              >
                <div className="flex items-center justify-between">
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
                        className="px-3 py-1.5 text-xs font-semibold rounded bg-indigo-600 hover:bg-indigo-700 text-white transition"
                      >
                        Acknowledge
                      </button>
                    )}
                    {(alert.status === 'new' || alert.status === 'acknowledged') && (
                      <button 
                        onClick={() => handleAction(alert.id, 'assigned')}
                        className="px-3 py-1.5 text-xs font-semibold rounded bg-surface-bg hover:bg-surface-border border border-surface-border text-slate-300 transition"
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
                        className="flex items-center space-x-1 px-3 py-1.5 text-xs font-semibold rounded bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/20 text-rose-400 transition"
                      >
                        <ArrowRightCircle className="h-3.5 w-3.5" />
                        <span>Escalate</span>
                      </button>
                    )}
                    {alert.status !== 'closed' && (
                      <button 
                        onClick={() => handleAction(alert.id, 'closed')}
                        className="flex items-center space-x-1 px-3 py-1.5 text-xs font-semibold rounded bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/20 text-emerald-400 transition"
                      >
                        <CheckCircle className="h-3.5 w-3.5" />
                        <span>Close</span>
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
