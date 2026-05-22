import { NavLink } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Bell, 
  Map, 
  Users, 
  ShieldAlert, 
  BarChart3, 
  Settings,
  ShieldAlert as BrandIcon
} from 'lucide-react';

export default function Sidebar() {
  const navItems = [
    { label: 'Dashboard', path: '/', icon: LayoutDashboard },
    { label: 'Alerts', path: '/alerts', icon: Bell },
    { label: 'Live Map', path: '/map', icon: Map },
    { label: 'Tourists', path: '/tourists', icon: Users },
    { label: 'Geo-fences', path: '/geofences', icon: ShieldAlert },
    { label: 'Analytics', path: '/analytics', icon: BarChart3 },
    { label: 'Settings', path: '/settings', icon: Settings },
  ];

  return (
    <aside className="w-64 h-screen bg-[#0F172A] border-r border-[#334155]/40 flex flex-col justify-between fixed left-0 top-0 z-40">
      <div className="flex flex-col flex-1">
        {/* Brand Header */}
        <div className="h-16 flex items-center px-6 border-b border-[#334155]/40 bg-[#0B0F19]/60">
          <div className="flex items-center space-x-2.5">
            <div className="h-8 w-8 rounded-lg bg-indigo-600 flex items-center justify-center shadow-lg shadow-indigo-600/30">
              <BrandIcon className="h-5 w-5 text-white" />
            </div>
            <div>
              <span className="font-outfit font-bold text-lg text-slate-100 tracking-tight leading-none">TravelSure</span>
              <span className="block text-[10px] text-indigo-400 font-semibold uppercase tracking-wider mt-0.5">Control Centre</span>
            </div>
          </div>
        </div>

        {/* Navigation Links */}
        <nav className="flex-1 py-6 px-4 space-y-1.5 overflow-y-auto">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.path}
                to={item.path}
                className={({ isActive }) => `
                  flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-medium transition duration-150 group
                  ${isActive 
                    ? 'bg-indigo-600/10 text-indigo-400 border border-indigo-500/20 shadow-glow-indigo' 
                    : 'text-slate-400 hover:text-slate-200 hover:bg-[#1E293B]/50 hover:border hover:border-transparent'
                  }
                `}
              >
                {({ isActive }) => (
                  <>
                    <Icon className={`h-5 w-5 transition duration-150 ${isActive ? 'text-indigo-400' : 'text-slate-400 group-hover:text-slate-300'}`} />
                    <span>{item.label}</span>
                  </>
                )}
              </NavLink>
            );
          })}
        </nav>
      </div>

      {/* Footer Info */}
      <div className="p-4 border-t border-[#334155]/40 bg-[#0B0F19]/30">
        <div className="flex items-center space-x-3 p-2 rounded-lg bg-[#1E293B]/30 border border-[#334155]/20">
          <div className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold text-slate-200 truncate">Central Node #01</p>
            <p className="text-[10px] text-slate-400 truncate">Status: Operational</p>
          </div>
        </div>
      </div>
    </aside>
  );
}
