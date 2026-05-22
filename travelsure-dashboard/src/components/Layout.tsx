import React from 'react';
import Sidebar from './Sidebar';
import { Bell, Shield, Calendar, Clock } from 'lucide-react';
import { format } from 'date-fns';

interface LayoutProps {
  children: React.ReactNode;
}

export default function Layout({ children }: LayoutProps) {
  const [time, setTime] = React.useState(new Date());

  React.useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div className="min-h-screen bg-[#0B0F19] text-slate-100 flex">
      {/* Fixed Left Sidebar */}
      <Sidebar />

      {/* Main Content Area */}
      <div className="flex-1 pl-64 flex flex-col min-h-screen">
        {/* Top Header */}
        <header className="h-16 border-b border-[#334155]/40 bg-[#0F172A]/70 backdrop-blur-md px-8 flex items-center justify-between sticky top-0 z-30">
          <div className="flex items-center space-x-6">
            {/* System Status Node */}
            <div className="flex items-center space-x-2 bg-[#1E293B]/60 border border-[#334155]/30 px-3 py-1.5 rounded-lg">
              <Shield className="h-4 w-4 text-emerald-400" />
              <span className="text-xs font-semibold text-slate-200">SIH-25002 Secure Node</span>
            </div>

            {/* Live Clock & Calendar */}
            <div className="hidden md:flex items-center space-x-4 text-xs font-medium text-slate-400">
              <div className="flex items-center space-x-1.5">
                <Calendar className="h-3.5 w-3.5" />
                <span>{format(time, 'EEE, MMM dd, yyyy')}</span>
              </div>
              <div className="flex items-center space-x-1.5 border-l border-slate-700 pl-4">
                <Clock className="h-3.5 w-3.5" />
                <span>{format(time, 'HH:mm:ss')}</span>
              </div>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            {/* Notifications Button */}
            <button className="relative p-2 text-slate-400 hover:text-slate-200 bg-[#1E293B]/40 hover:bg-[#1E293B]/70 border border-[#334155]/20 rounded-lg transition duration-150">
              <Bell className="h-5 w-5" />
              <span className="absolute top-1 right-1 h-2.5 w-2.5 bg-rose-500 rounded-full border-2 border-[#0F172A]" />
            </button>

            {/* Officer Profile Badge */}
            <div className="flex items-center space-x-3 pl-2 border-l border-slate-700">
              <div className="text-right hidden sm:block">
                <p className="text-sm font-semibold text-slate-200">Officer Abhijeet</p>
                <p className="text-[10px] text-slate-400 font-medium">Rescue Coordinator</p>
              </div>
              <div className="h-9 w-9 rounded-lg bg-indigo-600/20 border border-indigo-500/30 flex items-center justify-center font-bold text-indigo-300">
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
