import { NavLink } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Bell, 
  Map, 
  Users, 
  ShieldAlert, 
  BarChart3, 
  Settings,
  ShieldAlert as BrandIcon,
  BookOpen
} from 'lucide-react';

export default function Sidebar() {
  const navItems = [
    { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
    { label: 'Alerts', path: '/alerts', icon: Bell },
    { label: 'Live Map', path: '/map', icon: Map },
    { label: 'Tourists', path: '/tourists', icon: Users },
    { label: 'Geo-fences', path: '/geofences', icon: ShieldAlert },
    { label: 'Analytics', path: '/analytics', icon: BarChart3 },
    { label: 'Settings', path: '/settings', icon: Settings },
    { label: 'Help & Docs', path: '/help', icon: BookOpen },
  ];

  return (
    <aside 
      className="w-64 h-screen border-r flex flex-col justify-between fixed left-0 top-0 z-40 theme-transition"
      style={{ 
        backgroundColor: 'var(--sidebar-bg)', 
        borderColor: 'var(--sidebar-border)' 
      }}
    >
      <div className="flex flex-col flex-1">
        {/* Brand Header */}
        <div 
          className="h-16 flex items-center px-6 border-b theme-transition"
          style={{ 
            borderColor: 'var(--sidebar-border)',
            backgroundColor: 'var(--sidebar-header-bg)' 
          }}
        >
          <div className="flex items-center space-x-2.5">
            <div className="h-8 w-8 rounded-lg bg-indigo-600 flex items-center justify-center shadow-lg shadow-indigo-600/30">
              <BrandIcon className="h-5 w-5 text-white" />
            </div>
            <div>
              <span className="font-outfit font-bold text-lg tracking-tight leading-none" style={{ color: 'var(--color-dark-text)' }}>TravelSure</span>
              <span className="block text-[10px] font-semibold uppercase tracking-wider mt-0.5" style={{ color: 'var(--sidebar-text-active)' }}>Control Centre</span>
            </div>
          </div>
        </div>

        {/* Navigation Links */}
        <nav aria-label="Main Navigation" className="flex-1 py-6 px-4 space-y-1.5 overflow-y-auto">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.path}
                to={item.path}
                end
                className={({ isActive }) => `
                  flex items-center space-x-3 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200 group border focus:outline-none focus:ring-2 focus:ring-indigo-500
                  ${isActive 
                    ? 'shadow-sm' 
                    : 'border-transparent hover:opacity-80'
                  }
                `}
                style={({ isActive }) => ({
                  backgroundColor: isActive ? 'var(--sidebar-active)' : 'transparent',
                  color: isActive ? 'var(--sidebar-text-active)' : 'var(--sidebar-text)',
                  borderColor: isActive ? 'var(--sidebar-text-active)' + '33' : 'transparent'
                })}
              >
                {({ isActive }) => (
                  <>
                    <Icon 
                      className="h-5 w-5 transition duration-150" 
                      style={{ color: isActive ? 'var(--sidebar-text-active)' : 'var(--sidebar-text)' }}
                    />
                    <span>{item.label}</span>
                  </>
                )}
              </NavLink>
            );
          })}
        </nav>
      </div>

      {/* Footer Info */}
      <div 
        className="p-4 border-t theme-transition"
        style={{ 
          borderColor: 'var(--sidebar-border)',
          backgroundColor: 'var(--sidebar-header-bg)' 
        }}
      >
        <div 
          className="flex items-center space-x-3 p-2 rounded-lg border theme-transition"
          style={{ 
            backgroundColor: 'var(--surface-card)',
            borderColor: 'var(--sidebar-border)' 
          }}
        >
          <div className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold truncate" style={{ color: 'var(--color-dark-text)' }}>Central Node #01</p>
            <p className="text-[10px] truncate" style={{ color: 'var(--color-muted-text)' }}>Status: Operational</p>
          </div>
        </div>
      </div>
    </aside>
  );
}
