import React, { useState } from 'react';
import { 
  ShieldAlert, 
  Map as MapIcon, 
  Settings as SettingsIcon, 
  Activity, 
  Users, 
  ShieldCheck, 
  BellRing, 
  Compass, 
  Phone, 
  AlertTriangle,
  LogOut,
  MapPin,
  Clock,
  CheckCircle,
  Eye,
  Send,
  CloudAlert
} from 'lucide-react';

// Mock Alert Data matching PDF requirements
interface Alert {
  id: string;
  type: string;
  touristName: string;
  touristId: string;
  location: string;
  gps: string;
  time: string;
  priority: 'CRITICAL' | 'MEDIUM' | 'LOW';
  status: 'NEW' | 'RESPONDING' | 'RESOLVED';
  description: string;
  emergencyContact: string;
}

const INITIAL_ALERTS: Alert[] = [
  {
    id: 'AL-1092',
    type: 'Medical Emergency',
    touristName: 'Jane Smith',
    touristId: 'IND-90218-MH5',
    location: 'Gateway of India, Mumbai',
    gps: '18.9220, 72.8347',
    time: '5 minutes ago',
    priority: 'CRITICAL',
    status: 'RESPONDING',
    description: 'Difficulty breathing reported. Medical response team dispatched to coordinates.',
    emergencyContact: 'John Smith (Husband) - +91 98765 43210'
  },
  {
    id: 'AL-1093',
    type: 'Panic Button Activated',
    touristName: 'Arjun Kumar',
    touristId: 'IND-643269-HO5',
    location: 'Mumbai Central Railway Station',
    gps: '18.9696, 72.8193',
    time: '2 minutes ago',
    priority: 'MEDIUM',
    status: 'NEW',
    description: 'Tourist triggered the panic button. Feels followed near platform 4.',
    emergencyContact: 'Ramesh Kumar (Father) - +91 70386 20783'
  },
  {
    id: 'AL-1094',
    type: 'Assistance Alert',
    touristName: 'Michael Brown',
    touristId: 'USA-44129-NY3',
    location: 'Sanjay Gandhi National Park',
    gps: '19.2288, 72.9182',
    time: 'Just now',
    priority: 'LOW',
    status: 'NEW',
    description: 'Minor tracking anomaly. Lost route directions in the forest region.',
    emergencyContact: 'Sarah Brown (Wife) - +1 555-0199'
  }
];

export default function App() {
  const [alerts, setAlerts] = useState<Alert[]>(INITIAL_ALERTS);
  const [activeTab, setActiveTab] = useState<'home' | 'map' | 'alerts' | 'settings'>('home');
  const [selectedAlert, setSelectedAlert] = useState<Alert | null>(INITIAL_ALERTS[1]);
  const [officerStatus, setOfficerStatus] = useState<'ACTIVE' | 'OFF_DUTY'>('ACTIVE');
  const [geoFenceRadius, setGeoFenceRadius] = useState<number>(500);

  // Weather Alert state
  const [weatherAlert, setWeatherAlert] = useState({
    type: 'Heavy Rainfall / Landslide warning',
    severity: 'High',
    region: 'Western Ghats / Meghalaya Forest Zone',
    description: 'Sudden rainstorm expected. Restricting tourist tracking in mountainous routes.',
  });

  const handleUpdateStatus = (id: string, newStatus: 'RESPONDING' | 'RESOLVED') => {
    setAlerts(prev => prev.map(alert => alert.id === id ? { ...alert, status: newStatus } : alert));
    if (selectedAlert?.id === id) {
      setSelectedAlert(prev => prev ? { ...prev, status: newStatus } : null);
    }
  };

  const handleTriggerWeatherAlert = (e: React.FormEvent) => {
    e.preventDefault();
    alert('Broadcasted Weather Warning to all tourists in the affected area via App notification & SMS.');
  };

  const activeAlertsCount = alerts.filter(a => a.status !== 'RESOLVED').length;

  return (
    <div className="flex h-screen overflow-hidden bg-[#0A0E1A] text-slate-100 font-sans">
      
      {/* SIDEBAR NAVIGATION */}
      <aside className="w-64 bg-slate-900/60 border-r border-slate-800 flex flex-col justify-between backdrop-blur-xl">
        <div>
          {/* Brand Header */}
          <div className="p-6 flex items-center gap-3 border-b border-slate-800/80">
            <div className="p-2.5 bg-indigo-600 rounded-xl text-white shadow-lg shadow-indigo-600/30">
              <Compass className="w-6 h-6 animate-spin-slow" />
            </div>
            <div>
              <span className="font-extrabold text-xl tracking-tight text-white block">TravelTrek</span>
              <span className="text-[10px] text-indigo-400 font-bold uppercase tracking-widest">Authority Portal</span>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="p-4 space-y-1.5">
            <button 
              onClick={() => setActiveTab('home')}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-semibold transition-all duration-200 ${
                activeTab === 'home' 
                  ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/25' 
                  : 'text-slate-400 hover:bg-slate-800/50 hover:text-white'
              }`}
            >
              <Activity className="w-5 h-5" />
              Overview Hub
            </button>
            <button 
              onClick={() => setActiveTab('map')}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-semibold transition-all duration-200 ${
                activeTab === 'map' 
                  ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/25' 
                  : 'text-slate-400 hover:bg-slate-800/50 hover:text-white'
              }`}
            >
              <MapIcon className="w-5 h-5" />
              Live Tracking Map
            </button>
            <button 
              onClick={() => setActiveTab('alerts')}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-semibold justify-between transition-all duration-200 ${
                activeTab === 'alerts' 
                  ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/25' 
                  : 'text-slate-400 hover:bg-slate-800/50 hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3">
                <ShieldAlert className="w-5 h-5" />
                Emergency Alerts
              </div>
              {activeAlertsCount > 0 && (
                <span className="bg-red-500 text-white text-[11px] px-2 py-0.5 rounded-full font-bold animate-pulse">
                  {activeAlertsCount}
                </span>
              )}
            </button>
            <button 
              onClick={() => setActiveTab('settings')}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-semibold transition-all duration-200 ${
                activeTab === 'settings' 
                  ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/25' 
                  : 'text-slate-400 hover:bg-slate-800/50 hover:text-white'
              }`}
            >
              <SettingsIcon className="w-5 h-5" />
              System Settings
            </button>
          </nav>
        </div>

        {/* Sidebar Footer */}
        <div className="p-4 border-t border-slate-800/60 bg-slate-950/20">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 font-medium">Logged in as</p>
              <p className="text-sm font-bold text-white">Officer ID: 12345</p>
            </div>
            <button 
              title="Logout"
              className="p-2 text-slate-400 hover:text-red-400 hover:bg-slate-800/80 rounded-lg transition-all"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </aside>

      {/* MAIN CONTENT AREA */}
      <main className="flex-1 flex flex-col overflow-hidden">
        
        {/* HEADER SECTION */}
        <header className="h-20 bg-slate-900/30 border-b border-slate-800/60 px-8 flex items-center justify-between backdrop-blur-md">
          <div className="flex items-center gap-4">
            <h1 className="text-2xl font-bold tracking-tight text-white capitalize">{activeTab} panel</h1>
            <div className="h-6 w-px bg-slate-800"></div>
            <div className="flex items-center gap-2">
              <span className={`h-2.5 w-2.5 rounded-full ${officerStatus === 'ACTIVE' ? 'bg-emerald-500 animate-pulse' : 'bg-slate-500'}`}></span>
              <span className="text-xs font-semibold text-slate-300">
                Duty Status: <span className="font-bold text-white">{officerStatus}</span>
              </span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button 
              onClick={() => setOfficerStatus(prev => prev === 'ACTIVE' ? 'OFF_DUTY' : 'ACTIVE')}
              className={`px-4 py-2 rounded-xl text-xs font-semibold border transition-all ${
                officerStatus === 'ACTIVE' 
                  ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500/20'
                  : 'border-slate-700 bg-slate-800/50 text-slate-300 hover:bg-slate-700'
              }`}
            >
              Toggle Duty Status
            </button>
            <div className="relative">
              <button className="p-2.5 bg-slate-800/70 border border-slate-700/80 hover:bg-slate-700 rounded-xl text-slate-300 relative transition-all">
                <BellRing className="w-4 h-4" />
                {activeAlertsCount > 0 && (
                  <span className="absolute -top-1 -right-1 w-2.5 h-2.5 bg-red-500 rounded-full"></span>
                )}
              </button>
            </div>
          </div>
        </header>

        {/* CONTAINER FOR PAGE TABS */}
        <div className="flex-1 overflow-y-auto p-8">
          
          {/* TAB 1: OVERVIEW HUB (HOME) */}
          {activeTab === 'home' && (
            <div className="space-y-8">
              
              {/* Analytics Cards */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                
                {/* Stats 1: Active Alerts */}
                <div className="glass-panel p-6 rounded-2xl glow-border-red relative overflow-hidden">
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="text-sm font-semibold text-slate-400 uppercase tracking-wider">Active Alerts</p>
                      <h3 className="text-4xl font-extrabold mt-2 text-red-500 font-mono tracking-tight">{activeAlertsCount}</h3>
                    </div>
                    <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-xl text-red-400">
                      <ShieldAlert className="w-6 h-6" />
                    </div>
                  </div>
                  <div className="mt-4 text-xs text-red-400/80 flex items-center gap-1">
                    <span className="inline-block w-1.5 h-1.5 bg-red-500 rounded-full animate-ping"></span>
                    Requires immediate action
                  </div>
                </div>

                {/* Stats 2: Active Tourists */}
                <div className="glass-panel p-6 rounded-2xl border-slate-800">
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="text-sm font-semibold text-slate-400 uppercase tracking-wider">Active Tourists</p>
                      <h3 className="text-4xl font-extrabold mt-2 text-white font-mono tracking-tight">45</h3>
                    </div>
                    <div className="p-3 bg-indigo-500/10 border border-indigo-500/20 rounded-xl text-indigo-400">
                      <Users className="w-6 h-6" />
                    </div>
                  </div>
                  <div className="mt-4 text-xs text-slate-400">
                    <span className="text-indigo-400 font-bold">12</span> traveling in high-risk zones
                  </div>
                </div>

                {/* Stats 3: Safe Zones */}
                <div className="glass-panel p-6 rounded-2xl border-slate-800">
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="text-sm font-semibold text-slate-400 uppercase tracking-wider">Active Safe Zones</p>
                      <h3 className="text-4xl font-extrabold mt-2 text-white font-mono tracking-tight">3</h3>
                    </div>
                    <div className="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-xl text-emerald-400">
                      <ShieldCheck className="w-6 h-6" />
                    </div>
                  </div>
                  <div className="mt-4 text-xs text-emerald-400">
                    Geo-fences initialized successfully
                  </div>
                </div>

                {/* Stats 4: Safety Rate */}
                <div className="glass-panel p-6 rounded-2xl border-slate-800">
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="text-sm font-semibold text-slate-400 uppercase tracking-wider">General Safety Rate</p>
                      <h3 className="text-4xl font-extrabold mt-2 text-white font-mono tracking-tight">92%</h3>
                    </div>
                    <div className="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-xl text-emerald-400">
                      <CheckCircle className="w-6 h-6" />
                    </div>
                  </div>
                  <div className="mt-4 text-xs text-slate-400">
                    Calculated from active tourist scores
                  </div>
                </div>

              </div>

              {/* Central Panel Layout: Alerts Log and Details */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                
                {/* Left: Active Alerts Panel */}
                <div className="lg:col-span-2 space-y-4">
                  <div className="flex justify-between items-center">
                    <h4 className="text-lg font-bold text-white flex items-center gap-2">
                      <AlertTriangle className="w-5 h-5 text-red-500" />
                      Active Dispatch Log
                    </h4>
                    <span className="text-xs text-slate-400 font-mono">Real-time update via WebSocket</span>
                  </div>

                  <div className="space-y-4.5">
                    {alerts.map(alert => (
                      <div 
                        key={alert.id}
                        onClick={() => setSelectedAlert(alert)}
                        className={`p-5 rounded-2xl cursor-pointer transition-all duration-200 border ${
                          selectedAlert?.id === alert.id 
                            ? 'bg-slate-800/80 border-indigo-500 glow-border-indigo' 
                            : 'glass-panel border-slate-800 hover:border-slate-700 hover:bg-slate-800/35'
                        }`}
                      >
                        <div className="flex justify-between items-start">
                          <div>
                            <div className="flex items-center gap-2 flex-wrap">
                              <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                                alert.priority === 'CRITICAL' 
                                  ? 'bg-red-500/20 text-red-400 border border-red-500/30' 
                                  : alert.priority === 'MEDIUM' 
                                  ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                                  : 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                              }`}>
                                {alert.priority}
                              </span>
                              <span className="text-xs text-slate-400 font-mono">{alert.time}</span>
                              <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                                alert.status === 'NEW'
                                  ? 'bg-red-900/30 text-red-300 border border-red-800/50'
                                  : 'bg-indigo-900/30 text-indigo-300 border border-indigo-800/50'
                              }`}>
                                {alert.status}
                              </span>
                            </div>
                            <h5 className="text-lg font-bold text-white mt-2">{alert.type}</h5>
                            <div className="flex items-center gap-4 text-xs text-slate-400 mt-2">
                              <span className="flex items-center gap-1">
                                <Users className="w-3.5 h-3.5" />
                                {alert.touristName} ({alert.touristId})
                              </span>
                              <span className="flex items-center gap-1">
                                <MapPin className="w-3.5 h-3.5" />
                                {alert.location}
                              </span>
                            </div>
                          </div>
                          <button 
                            onClick={(e) => {
                              e.stopPropagation();
                              setSelectedAlert(alert);
                              setActiveTab('map');
                            }}
                            className="p-2.5 bg-slate-800 border border-slate-700/80 hover:bg-indigo-600 hover:text-white rounded-xl text-slate-400 transition-all"
                            title="Locate on Map"
                          >
                            <MapIcon className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Right: Selected Alert Detail Screen */}
                <div className="space-y-4">
                  <h4 className="text-lg font-bold text-white">Emergency Response Actions</h4>
                  
                  {selectedAlert ? (
                    <div className="glass-panel p-6 rounded-2xl border-slate-800 space-y-6 relative overflow-hidden">
                      {selectedAlert.priority === 'CRITICAL' && (
                        <div className="absolute top-0 right-0 left-0 h-1.5 bg-red-500 animate-pulse"></div>
                      )}
                      
                      <div>
                        <span className="text-xs text-indigo-400 font-bold font-mono tracking-wider">{selectedAlert.id}</span>
                        <h5 className="text-xl font-bold text-white mt-1">{selectedAlert.type}</h5>
                        <p className="text-xs text-slate-400 mt-1">{selectedAlert.location}</p>
                      </div>

                      <div className="p-4 bg-slate-900/80 rounded-xl border border-slate-800 text-sm space-y-3">
                        <div>
                          <p className="text-xs text-slate-500 uppercase font-semibold">Incident Details</p>
                          <p className="text-slate-300 mt-0.5 font-medium">{selectedAlert.description}</p>
                        </div>
                        <div>
                          <p className="text-xs text-slate-500 uppercase font-semibold">Coordinates (GPS)</p>
                          <p className="text-white mt-0.5 font-mono text-xs flex items-center gap-1">
                            <span className="w-1.5 h-1.5 bg-red-500 rounded-full animate-ping"></span>
                            {selectedAlert.gps}
                          </p>
                        </div>
                        <div>
                          <p className="text-xs text-slate-500 uppercase font-semibold">Emergency Contacts</p>
                          <p className="text-slate-300 mt-0.5">{selectedAlert.emergencyContact}</p>
                        </div>
                      </div>

                      <div className="space-y-3">
                        <a 
                          href={`tel:${selectedAlert.emergencyContact.split(' - ').pop()}`}
                          className="w-full flex items-center justify-center gap-2 py-3 bg-slate-800 border border-slate-700 hover:bg-slate-700/80 text-white rounded-xl text-sm font-semibold transition-all"
                        >
                          <Phone className="w-4 h-4" />
                          Call Emergency Contact
                        </a>
                        
                        {selectedAlert.status === 'NEW' ? (
                          <button 
                            onClick={() => handleUpdateStatus(selectedAlert.id, 'RESPONDING')}
                            className="w-full flex items-center justify-center gap-2 py-3 bg-red-600 hover:bg-red-500 text-white rounded-xl text-sm font-bold shadow-lg shadow-red-600/20 transition-all"
                          >
                            <ShieldAlert className="w-4 h-4" />
                            Dispatch Emergency Response
                          </button>
                        ) : selectedAlert.status === 'RESPONDING' ? (
                          <button 
                            onClick={() => handleUpdateStatus(selectedAlert.id, 'RESOLVED')}
                            className="w-full flex items-center justify-center gap-2 py-3 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-sm font-bold shadow-lg shadow-emerald-600/20 transition-all"
                          >
                            <CheckCircle className="w-4 h-4" />
                            Mark Incident as Resolved
                          </button>
                        ) : (
                          <div className="py-3 bg-slate-800/50 border border-slate-700/30 text-center rounded-xl text-xs font-semibold text-emerald-400">
                            Incident successfully resolved and logged on-chain.
                          </div>
                        )}
                      </div>
                    </div>
                  ) : (
                    <div className="glass-panel p-8 rounded-2xl border-slate-800 text-center text-slate-400">
                      Select an alert from the active dispatch log to coordinate emergency actions.
                    </div>
                  )}
                </div>

              </div>

            </div>
          )}

          {/* TAB 2: LIVE TRACKING MAP */}
          {activeTab === 'map' && (
            <div className="h-full flex flex-col gap-6">
              
              {/* Map Info Header */}
              <div className="flex justify-between items-center bg-slate-900/30 border border-slate-800/80 p-5 rounded-2xl">
                <div>
                  <h4 className="text-lg font-bold text-white">Live Operations Map</h4>
                  <p className="text-xs text-slate-400">Showing active tourist coordinates, marked high-risk zones, and police outposts.</p>
                </div>
                <div className="flex items-center gap-3">
                  <div className="flex items-center gap-1.5 text-xs bg-red-500/10 border border-red-500/20 px-3 py-1.5 rounded-full text-red-400 font-bold">
                    <span className="w-1.5 h-1.5 bg-red-500 rounded-full animate-ping"></span>
                    2 SOS Active
                  </div>
                  <div className="flex items-center gap-1.5 text-xs bg-indigo-500/10 border border-indigo-500/20 px-3 py-1.5 rounded-full text-indigo-400 font-bold">
                    <Users className="w-3.5 h-3.5" />
                    45 Tourists Online
                  </div>
                </div>
              </div>

              {/* Map Canvas Placeholder & Control Box */}
              <div className="flex-1 min-h-[500px] rounded-3xl border border-slate-800/80 overflow-hidden relative bg-[#090D16]">
                {/* Visual grid representing map background */}
                <div 
                  className="absolute inset-0 bg-cover bg-center opacity-65 flex items-center justify-center"
                  style={{ 
                    backgroundImage: `radial-gradient(circle, rgba(99,102,241,0.08) 1px, transparent 1px)`, 
                    backgroundSize: '24px 24px' 
                  }}
                >
                  {/* Mock map graphic nodes */}
                  <div className="absolute top-1/4 left-1/3 text-center">
                    <div className="p-3 bg-red-500 text-white rounded-full pulse-emergency shadow-lg inline-block cursor-pointer" onClick={() => setSelectedAlert(alerts[1])}>
                      <ShieldAlert className="w-5 h-5" />
                    </div>
                    <span className="block text-[10px] mt-1 font-bold text-red-400 bg-slate-950/80 px-2 py-0.5 rounded">Arjun Kumar (SOS)</span>
                  </div>

                  <div className="absolute top-2/3 right-1/4 text-center">
                    <div className="p-3 bg-red-500 text-white rounded-full pulse-emergency shadow-lg inline-block cursor-pointer" onClick={() => setSelectedAlert(alerts[0])}>
                      <ShieldAlert className="w-5 h-5" />
                    </div>
                    <span className="block text-[10px] mt-1 font-bold text-red-400 bg-slate-950/80 px-2 py-0.5 rounded">Jane Smith (SOS)</span>
                  </div>

                  <div className="absolute top-1/3 right-1/3 text-center">
                    <div className="p-2 bg-indigo-600 text-white rounded-full shadow-lg inline-block">
                      <Users className="w-4 h-4" />
                    </div>
                    <span className="block text-[10px] mt-1 text-slate-300 bg-slate-950/80 px-2 py-0.5 rounded">Tourist group (3)</span>
                  </div>

                  <div className="absolute bottom-1/3 left-1/4">
                    {/* Fenced Area Circle */}
                    <div className="w-40 h-40 border-2 border-red-500/20 bg-red-500/5 rounded-full flex items-center justify-center">
                      <span className="text-[10px] text-red-400 font-bold bg-slate-950/80 px-2 py-0.5 rounded">Fenced Danger Zone</span>
                    </div>
                  </div>

                  <span className="text-slate-500 text-xs font-mono select-none">
                    [ Mapbox / Leaflet WebGL GIS Overlay Canvas ]
                  </span>
                </div>

                {/* Map Control overlay (Left side) */}
                <div className="absolute bottom-6 left-6 w-80 glass-panel p-5 rounded-2xl border-slate-800 space-y-4">
                  <h5 className="font-bold text-sm text-white">Map Control Layers</h5>
                  <div className="space-y-2.5">
                    <label className="flex items-center justify-between text-xs text-slate-300">
                      <span>Show Geo-fence Boundaries</span>
                      <input type="checkbox" defaultChecked className="accent-indigo-600 rounded bg-slate-800 border-slate-700" />
                    </label>
                    <label className="flex items-center justify-between text-xs text-slate-300">
                      <span>Show Police/SOS Outposts</span>
                      <input type="checkbox" defaultChecked className="accent-indigo-600 rounded bg-slate-800 border-slate-700" />
                    </label>
                    <label className="flex items-center justify-between text-xs text-slate-300">
                      <span>Show Safe Zones</span>
                      <input type="checkbox" defaultChecked className="accent-indigo-600 rounded bg-slate-800 border-slate-700" />
                    </label>
                    <label className="flex items-center justify-between text-xs text-slate-300">
                      <span>Cluster Nearby Tourists</span>
                      <input type="checkbox" className="accent-indigo-600 rounded bg-slate-800 border-slate-700" />
                    </label>
                  </div>
                </div>

                {/* Map Legend overlay (Right top) */}
                <div className="absolute top-6 right-6 glass-panel p-4 rounded-xl border-slate-800 text-[11px] space-y-2">
                  <h6 className="font-bold text-slate-300 uppercase tracking-wider text-[10px]">Map Legend</h6>
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-red-500 inline-block"></span>
                      <span>Active Emergency (SOS)</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-indigo-500 inline-block"></span>
                      <span>Tourist Location</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="w-2.5. h-2.5 rounded-full bg-emerald-500 inline-block"></span>
                      <span>Police Outpost / Station</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="w-5 h-1 border-t-2 border-red-500/40 inline-block"></span>
                      <span>Geo-fenced Barrier</span>
                    </div>
                  </div>
                </div>

              </div>

            </div>
          )}

          {/* TAB 3: EMERGENCY ALERTS (DETAILED DISPATCH LIST) */}
          {activeTab === 'alerts' && (
            <div className="space-y-6">
              
              <div className="flex justify-between items-center">
                <div>
                  <h4 className="text-xl font-bold text-white">Incident Dispatch Control</h4>
                  <p className="text-xs text-slate-400">View logs, deploy emergency assistance, and resolve cases.</p>
                </div>
              </div>

              <div className="grid grid-cols-1 gap-4">
                {alerts.map(alert => (
                  <div key={alert.id} className="glass-panel p-6 rounded-2xl border-slate-800 flex justify-between items-center gap-8 flex-wrap md:flex-nowrap">
                    <div className="space-y-2">
                      <div className="flex items-center gap-2">
                        <span className="text-xs text-indigo-400 font-mono font-bold">{alert.id}</span>
                        <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                          alert.priority === 'CRITICAL' ? 'bg-red-500/20 text-red-400 border border-red-500/30' : 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                        }`}>
                          {alert.priority}
                        </span>
                        <span className="text-xs text-slate-500 font-mono">{alert.time}</span>
                      </div>
                      <h5 className="text-lg font-bold text-white">{alert.type}</h5>
                      <p className="text-sm text-slate-300 font-medium">{alert.description}</p>
                      <div className="flex items-center gap-6 text-xs text-slate-400">
                        <span><strong>Tourist:</strong> {alert.touristName}</span>
                        <span><strong>ID:</strong> {alert.touristId}</span>
                        <span><strong>GPS:</strong> {alert.gps}</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-3 w-full md:w-auto">
                      <button 
                        onClick={() => {
                          setSelectedAlert(alert);
                          setActiveTab('home');
                        }}
                        className="px-4 py-2.5 bg-slate-800 border border-slate-700 hover:bg-slate-700 text-slate-200 rounded-xl text-xs font-semibold flex-1 md:flex-none transition-all"
                      >
                        Action Center
                      </button>
                      
                      {alert.status === 'NEW' && (
                        <button 
                          onClick={() => handleUpdateStatus(alert.id, 'RESPONDING')}
                          className="px-4 py-2.5 bg-red-600 hover:bg-red-500 text-white rounded-xl text-xs font-bold flex-1 md:flex-none transition-all"
                        >
                          Dispatch
                        </button>
                      )}
                      
                      {alert.status === 'RESPONDING' && (
                        <button 
                          onClick={() => handleUpdateStatus(alert.id, 'RESOLVED')}
                          className="px-4 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-bold flex-1 md:flex-none transition-all"
                        >
                          Resolve
                        </button>
                      )}

                      {alert.status === 'RESOLVED' && (
                        <span className="px-4 py-2 bg-slate-900 border border-slate-800 text-emerald-400 text-xs font-bold rounded-xl flex-1 md:flex-none text-center">
                          Resolved
                        </span>
                      )}
                    </div>
                  </div>
                ))}
              </div>

            </div>
          )}

          {/* TAB 4: SYSTEM CONFIGURATION (SETTINGS) */}
          {activeTab === 'settings' && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              
              {/* Box 1: Geo-fencing & Safe Zones Setup */}
              <div className="glass-panel p-6 rounded-2xl border-slate-800 space-y-6">
                <h4 className="text-lg font-bold text-white flex items-center gap-2">
                  <Compass className="w-5 h-5 text-indigo-400" />
                  Geo-fencing Coordinates Configuration
                </h4>
                
                <div className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Default Alert Proximity Radius (Meters)</label>
                    <input 
                      type="range" 
                      min="100" 
                      max="2000" 
                      step="50"
                      value={geoFenceRadius} 
                      onChange={(e) => setGeoFenceRadius(Number(e.target.value))}
                      className="w-full h-2 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-600"
                    />
                    <div className="flex justify-between text-xs text-slate-400 mt-2 font-mono">
                      <span>100m</span>
                      <span className="text-indigo-400 font-bold">{geoFenceRadius} meters</span>
                      <span>2000m</span>
                    </div>
                  </div>

                  <div className="pt-4 border-t border-slate-800/80 space-y-3">
                    <h5 className="text-sm font-bold text-white">Create High-Risk Alert Area</h5>
                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="block text-[10px] text-slate-500 uppercase font-bold mb-1">Center Latitude</label>
                        <input type="text" placeholder="18.9696" className="w-full bg-slate-900 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-indigo-600" />
                      </div>
                      <div>
                        <label className="block text-[10px] text-slate-500 uppercase font-bold mb-1">Center Longitude</label>
                        <input type="text" placeholder="72.8193" className="w-full bg-slate-900 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-indigo-600" />
                      </div>
                    </div>
                    <button className="w-full py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-xs font-bold transition-all">
                      Add Boundary Fence Overlay
                    </button>
                  </div>
                </div>
              </div>

              {/* Box 2: Broadcast Weather Warnings & Alerts */}
              <div className="glass-panel p-6 rounded-2xl border-slate-800 space-y-6">
                <h4 className="text-lg font-bold text-white flex items-center gap-2">
                  <CloudAlert className="w-5 h-5 text-amber-500" />
                  Broadcast Weather / Security Emergency
                </h4>
                
                <form onSubmit={handleTriggerWeatherAlert} className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Alert Type / Title</label>
                    <input 
                      type="text" 
                      value={weatherAlert.type}
                      onChange={(e) => setWeatherAlert(prev => ({ ...prev, type: e.target.value }))}
                      className="w-full bg-slate-900 border border-slate-800 rounded-xl px-4 py-2.5 text-xs text-white focus:outline-none focus:border-indigo-600"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Affected region</label>
                    <input 
                      type="text" 
                      value={weatherAlert.region}
                      onChange={(e) => setWeatherAlert(prev => ({ ...prev, region: e.target.value }))}
                      className="w-full bg-slate-900 border border-slate-800 rounded-xl px-4 py-2.5 text-xs text-white focus:outline-none focus:border-indigo-600"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Warning advisory message</label>
                    <textarea 
                      rows={3}
                      value={weatherAlert.description}
                      onChange={(e) => setWeatherAlert(prev => ({ ...prev, description: e.target.value }))}
                      className="w-full bg-slate-900 border border-slate-800 rounded-xl px-4 py-2.5 text-xs text-white focus:outline-none focus:border-indigo-600 resize-none"
                    />
                  </div>
                  <button type="submit" className="w-full py-3 bg-amber-600 hover:bg-amber-500 text-white rounded-xl text-xs font-bold shadow-lg shadow-amber-600/20 transition-all flex items-center justify-center gap-2">
                    <Send className="w-3.5 h-3.5" />
                    Broadcast Advisory Alert
                  </button>
                </form>
              </div>

            </div>
          )}

        </div>
      </main>

    </div>
  );
}
