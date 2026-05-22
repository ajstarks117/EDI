import { useEffect, useState, type ReactNode } from 'react';
import Sidebar from './Sidebar';
import { Bell, Shield, Calendar, Clock, Sun, Moon, Wifi } from 'lucide-react';
import { format } from 'date-fns';
import { useUIStore } from '../store/useUIStore';
import { useDemoStore } from '../store/useDemoStore';
import DemoOverlay from './DemoOverlay';
import { useWebSocket } from '../hooks/useWebSocket';
import NotificationBanner from './NotificationBanner';
import { useSettingsStore } from '../store/useSettingsStore';
import { useAlertStore } from '../store/useAlertStore';
import { useTouristStore } from '../store/useTouristStore';
import FPSMonitor from './FPSMonitor';

interface LayoutProps {
  children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {
  const [time, setTime] = useState(new Date());
  const { darkMode, toggleDarkMode, connectionStatus } = useUIStore();
  const { devModeEnabled } = useSettingsStore();
  const initializeAlerts = useAlertStore(state => state.initializeData);
  const initializeTourists = useTouristStore(state => state.initializeData);

  // Initialize global websocket connection
  useWebSocket();

  useEffect(() => {
    // Initial data fetch
    initializeAlerts();
    initializeTourists();
    
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, [initializeAlerts, initializeTourists]);

  const getStatusColor = () => {
    switch (connectionStatus) {
      case 'connected': return 'text-emerald-400';
      case 'connecting': return 'text-amber-400';
      case 'disconnected': return 'text-rose-400';
      default: return 'text-slate-400';
    }
  };

  const getStatusBg = () => {
    switch (connectionStatus) {
      case 'connected': return 'bg-emerald-500';
      case 'connecting': return 'bg-amber-500';
      case 'disconnected': return 'bg-rose-500';
      default: return 'bg-slate-500';
    }
  };

  const getStatusBgPing = () => {
    switch (connectionStatus) {
      case 'connected': return 'bg-emerald-400';
      case 'connecting': return 'bg-amber-400';
      case 'disconnected': return 'bg-rose-400';
      default: return 'bg-slate-400';
    }
  };

  return (
    <div className="min-h-screen bg-surface text-dark-text flex flex-col theme-transition">
      <a href="#main-content" className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 z-50 bg-indigo-600 text-white px-4 py-2 rounded shadow-lg outline-none focus:ring-2 focus:ring-indigo-400">
        Skip to main content
      </a>
      <NotificationBanner />
      <div className="flex flex-1 relative">
        {/* Fixed Left Sidebar */}
        <Sidebar />

        {/* Main Content Area */}
        <div className="flex-1 pl-64 flex flex-col min-h-screen w-full">
          {/* Top Header */}
          <header className="h-16 border-b border-surface-border/40 bg-surface-card/70 backdrop-blur-md px-8 flex items-center justify-between sticky top-0 z-30 theme-transition">
            <div className="flex items-center space-x-6">
              {/* Environment Badge */}
              <div className="flex items-center space-x-2 bg-surface-card/60 border border-surface-border/30 px-3 py-1.5 rounded-md">
                <Shield className="h-4 w-4 text-success-green" />
                <span className="text-xs font-semibold">SIH-25002 Secure Node</span>
              </div>

            <div id="connectivity-indicator" className="flex items-center space-x-2 bg-surface-card/60 border border-surface-border/30 px-3 py-1.5 rounded-md">
              <Wifi className={`h-4 w-4 ${getStatusColor()}`} />
              <span className={`text-xs font-semibold capitalize ${getStatusColor()}`}>{connectionStatus}</span>
              <span className="relative flex h-2 w-2">
                <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${getStatusBgPing()}`}></span>
                <span className={`relative inline-flex rounded-full h-2 w-2 ${getStatusBg()}`}></span>
              </span>
            </div>

            {/* Live Clock & Calendar */}
            <div className="hidden md:flex items-center space-x-4 text-xs font-medium text-muted-text">
              <div className="flex items-center space-x-1.5">
                <Calendar className="h-3.5 w-3.5" />
                <span>{format(time, 'EEE, MMM dd, yyyy')}</span>
              </div>
              <div className="flex items-center space-x-1.5 border-l border-surface-border pl-4">
                <Clock className="h-3.5 w-3.5" />
                <span>{format(time, 'HH:mm:ss')}</span>
              </div>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            {/* Dark / Light Mode Toggle */}
            <button
              id="theme-toggle"
              onClick={toggleDarkMode}
              className="relative p-2 text-muted-text hover:text-dark-text bg-surface-card/40 hover:bg-surface-card/70 border border-surface-border/20 rounded-md transition duration-150 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              aria-label="Toggle theme"
            >
              {darkMode ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
            </button>

            {/* Demo Mode Toggle */}
            <button
              id="demo-toggle"
              onClick={() => useDemoStore.getState().toggle()}
              className="ml-2 relative p-2 text-muted-text hover:text-dark-text bg-surface-card/40 hover:bg-surface-card/70 border border-surface-border/20 rounded-md transition duration-150 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              aria-label="Toggle Demo Mode"
            >
              Demo
            </button>

            {/* Notifications Button */}
            <button
              id="notifications-btn"
              aria-label="View notifications"
              className="relative p-2 text-muted-text hover:text-dark-text bg-surface-card/40 hover:bg-surface-card/70 border border-surface-border/20 rounded-md transition duration-150 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <Bell className="h-5 w-5" />
              <span className="absolute top-1 right-1 h-2.5 w-2.5 bg-alert-red rounded-full border-2 border-surface" />
            </button>

            {/* Officer Profile Badge */}
            <div className="flex items-center space-x-3 pl-2 border-l border-surface-border">
              <div className="text-right hidden sm:block">
                <p className="text-sm font-semibold">{useSettingsStore().operatorProfile.name}</p>
                <p className="text-[10px] text-muted-text font-medium">{useSettingsStore().operatorProfile.role}</p>
              </div>
              <div className="h-9 w-9 rounded-md bg-safety-teal/20 border border-safety-teal/30 flex items-center justify-center font-bold text-safety-teal uppercase">
                {useSettingsStore().operatorProfile.name.slice(0, 2)}
              </div>
            </div>
          </div>
        </header>

        {/* Scrollable Page Wrapper */}
        <main id="main-content" tabIndex={-1} className="flex-1 p-8 overflow-y-auto relative focus:outline-none">
          <div className="max-w-7xl mx-auto">
            {children}
            {devModeEnabled && <FPSMonitor />}
          </div>
        </main>
        </div>
        {/* Demo Overlay */}
        {useDemoStore().enabled && <DemoOverlay />}
      </div>
    </div>
  );
}
