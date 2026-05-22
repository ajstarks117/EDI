import { Shield, AlertTriangle, Users, MapPin, Bug } from 'lucide-react';
import { useAlertStore } from '../store/useAlertStore';
import { useTouristStore } from '../store/useTouristStore';
import { useGeofenceStore } from '../store/useGeofenceStore';

export default function Dashboard() {
  const { addAlert, clearAlerts } = useAlertStore();
  const { selectTourist, updatePosition } = useTouristStore();
  const { toggleFilter } = useGeofenceStore();

  const stats = [
    { label: 'Active Tourists', value: '1,248', icon: Users, color: 'text-indigo-400', bg: 'bg-indigo-500/10' },
    { label: 'Critical Alerts', value: '3', icon: AlertTriangle, color: 'text-rose-400', bg: 'bg-rose-500/10' },
    { label: 'Tracked Devices', value: '1,245', icon: MapPin, color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    { label: 'System Status', value: 'Optimal', icon: Shield, color: 'text-sky-400', bg: 'bg-sky-500/10' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-slate-100">Control Operations Dashboard</h1>
        <p className="text-slate-400 mt-1">Real-time status monitoring, alert dispatching, and tourist safety oversight.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.label} className="glass-panel p-6 rounded-xl flex items-center space-x-4">
              <div className={`p-3 rounded-lg ${stat.bg}`}>
                <Icon className={`h-6 w-6 ${stat.color}`} />
              </div>
              <div>
                <p className="text-sm font-medium text-slate-400">{stat.label}</p>
                <p className="text-2xl font-bold text-slate-100 mt-0.5">{stat.value}</p>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 glass-panel p-6 rounded-xl space-y-4">
          <h2 className="text-xl font-semibold text-slate-200">Active Alert Feeds</h2>
          <div className="space-y-3">
            <div className="glow-border-red bg-rose-500/5 p-4 rounded-lg flex justify-between items-center">
              <div className="flex items-center space-x-3">
                <div className="h-2 w-2 rounded-full bg-rose-500 animate-pulse" />
                <div>
                  <h4 className="font-semibold text-rose-200">SOS Triggered - Tourist ID #8491</h4>
                  <p className="text-xs text-rose-300/80">Location: Valley of Flowers Trail | Coordinates: 30.7282, 79.6053</p>
                </div>
              </div>
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-rose-500/20 text-rose-300">CRITICAL</span>
            </div>
            <div className="border border-amber-500/30 bg-amber-500/5 p-4 rounded-lg flex justify-between items-center">
              <div className="flex items-center space-x-3">
                <div className="h-2 w-2 rounded-full bg-amber-500 animate-pulse" />
                <div>
                  <h4 className="font-semibold text-amber-200">Geofence Exit Alert - Tourist ID #1042</h4>
                  <p className="text-xs text-amber-300/80">Location: Hemkund Sahib High Risk Boundary</p>
                </div>
              </div>
              <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-amber-500/20 text-amber-300">WARNING</span>
            </div>
          </div>
        </div>
        <div className="glass-panel p-6 rounded-xl space-y-4">
          <h2 className="text-xl font-semibold text-slate-200">Incident Quick Actions</h2>
          <div className="grid grid-cols-1 gap-3">
            <button className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-medium py-2.5 px-4 rounded-lg transition">
              Broadcast Weather Warning
            </button>
            <button className="w-full bg-slate-800 hover:bg-slate-750 text-slate-200 font-medium py-2.5 px-4 rounded-lg border border-slate-700 transition">
              Sync Smart Contracts
            </button>
          </div>
        </div>
      </div>

      {/* Temporary Debug Panel */}
      <div className="glass-panel p-6 rounded-xl space-y-4 border-dashed border-2 border-indigo-500/30">
        <div className="flex items-center space-x-2 text-indigo-400">
          <Bug className="h-5 w-5" />
          <h2 className="text-lg font-semibold">Store State Debugger</h2>
        </div>
        <div className="flex flex-wrap gap-3">
          <button 
            onClick={() => addAlert({ priority: 'P0', message: 'SOS Panic Button pressed!', touristId: 't-103' })}
            className="bg-rose-500/20 text-rose-300 hover:bg-rose-500/30 px-3 py-1.5 rounded text-sm font-medium transition"
          >
            Add Alert
          </button>
          <button 
            onClick={() => clearAlerts()}
            className="bg-slate-800 text-slate-300 hover:bg-slate-700 px-3 py-1.5 rounded text-sm font-medium transition"
          >
            Clear Alerts
          </button>
          <button 
            onClick={() => selectTourist('tourist-456')}
            className="bg-indigo-500/20 text-indigo-300 hover:bg-indigo-500/30 px-3 py-1.5 rounded text-sm font-medium transition"
          >
            Select Tourist
          </button>
          <button 
            onClick={() => updatePosition('tourist-456', { lat: 30.0, lng: 79.0 })}
            className="bg-emerald-500/20 text-emerald-300 hover:bg-emerald-500/30 px-3 py-1.5 rounded text-sm font-medium transition"
          >
            Update Position
          </button>
          <button 
            onClick={() => toggleFilter('danger')}
            className="bg-amber-500/20 text-amber-300 hover:bg-amber-500/30 px-3 py-1.5 rounded text-sm font-medium transition"
          >
            Toggle Danger Filter
          </button>
        </div>
      </div>
    </div>
  );
}
