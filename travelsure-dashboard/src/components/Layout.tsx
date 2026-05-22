import { useEffect, useState, useCallback, type ReactNode } from 'react';
import Sidebar from './Sidebar';
import { Bell, Shield, Calendar, Clock, Sun, Moon, Wifi } from 'lucide-react';
import { format } from 'date-fns';

interface LayoutProps {
  children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {
  const [time, setTime] = useState(new Date());
  const [isDark, setIsDark] = useState(true); // default to dark (ops dashboard)

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  /* Sync the .dark class on <html> whenever the toggle changes */
  useEffect(() => {
    const root = document.documentElement;
    if (isDark) {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  }, [isDark]);

  const toggleTheme = useCallback(() => setIsDark((prev) => !prev), []);

  return (
    <div className="min-h-screen bg-surface text-dark-text flex transition-colors duration-300">
      {/* Fixed Left Sidebar */}
      <Sidebar />

      {/* Main Content Area */}
      <div className="flex-1 pl-64 flex flex-col min-h-screen">
        {/* Top Header */}
        <header className="h-16 border-b border-surface-border/40 bg-surface-card/70 backdrop-blur-md px-8 flex items-center justify-between sticky top-0 z-30 transition-colors duration-300">
          <div className="flex items-center space-x-6">
            {/* Environment Badge */}
            <div className="flex items-center space-x-2 bg-surface-card/60 border border-surface-border/30 px-3 py-1.5 rounded-md">
              <Shield className="h-4 w-4 text-success-green" />
              <span className="text-xs font-semibold">SIH-25002 Secure Node</span>
            </div>

            {/* Connectivity Indicator */}
            <div id="connectivity-indicator" className="flex items-center space-x-2 bg-surface-card/60 border border-surface-border/30 px-3 py-1.5 rounded-md">
              <Wifi className="h-4 w-4 text-emerald-400" />
              <span className="text-xs font-semibold text-emerald-400">Connected</span>
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
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
              onClick={toggleTheme}
              className="relative p-2 text-muted-text hover:text-dark-text bg-surface-card/40 hover:bg-surface-card/70 border border-surface-border/20 rounded-md transition duration-150"
              aria-label="Toggle theme"
            >
              {isDark ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
            </button>

            {/* Notifications Button */}
            <button
              id="notifications-btn"
              className="relative p-2 text-muted-text hover:text-dark-text bg-surface-card/40 hover:bg-surface-card/70 border border-surface-border/20 rounded-md transition duration-150"
            >
              <Bell className="h-5 w-5" />
              <span className="absolute top-1 right-1 h-2.5 w-2.5 bg-alert-red rounded-full border-2 border-surface" />
            </button>

            {/* Officer Profile Badge */}
            <div className="flex items-center space-x-3 pl-2 border-l border-surface-border">
              <div className="text-right hidden sm:block">
                <p className="text-sm font-semibold">Officer Abhijeet</p>
                <p className="text-[10px] text-muted-text font-medium">Rescue Coordinator</p>
              </div>
              <div className="h-9 w-9 rounded-md bg-safety-teal/20 border border-safety-teal/30 flex items-center justify-center font-bold text-safety-teal">
                OA
              </div>
            </div>
          </div>
        </header>

        {/* Scrollable Page Wrapper */}
        <main className="flex-1 p-8 overflow-y-auto">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
