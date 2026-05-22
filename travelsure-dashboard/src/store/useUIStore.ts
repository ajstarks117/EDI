import { create } from 'zustand';

export interface Toast {
  id: string;
  message: string;
  type?: 'success' | 'error' | 'info';
}

interface UIState {
  darkMode: boolean;
  rightPanelOpen: boolean;
  toasts: Toast[];
  connectionStatus: 'connected' | 'connecting' | 'disconnected';
  flyToLocation: [number, number] | null;
  notificationPermission: NotificationPermission | 'default';
  bannerDismissed: boolean;
  toggleDarkMode: () => void;
  setRightPanelOpen: (isOpen: boolean) => void;
  addToast: (toast: Omit<Toast, 'id'>) => void;
  removeToast: (id: string) => void;
  setConnectionStatus: (status: 'connected' | 'connecting' | 'disconnected') => void;
  setFlyToLocation: (loc: [number, number] | null) => void;
  setNotificationPermission: (permission: NotificationPermission) => void;
  dismissBanner: () => void;
}

// Initial dark mode: check localStorage first, then prefers-color-scheme, default to dark for ops
const getInitialDarkMode = (): boolean => {
  if (typeof window === 'undefined') return true;
  const stored = localStorage.getItem('traveltrek-dark-mode');
  if (stored !== null) return stored === 'true';
  return window.matchMedia('(prefers-color-scheme: dark)').matches || true;
};

// Sync the .dark class immediately so there's no flash
const applyDarkClass = (isDark: boolean) => {
  if (typeof window === 'undefined') return;
  const root = document.documentElement;
  if (isDark) {
    root.classList.add('dark');
  } else {
    root.classList.remove('dark');
  }
};

// Apply on module load
const initialDark = getInitialDarkMode();
applyDarkClass(initialDark);

const getInitialBannerDismissed = (): boolean => {
  if (typeof window === 'undefined') return false;
  return localStorage.getItem('traveltrek-banner-dismissed') === 'true';
};

export const useUIStore = create<UIState>((set) => ({
  darkMode: initialDark,
  rightPanelOpen: false,
  toasts: [],
  connectionStatus: 'disconnected',
  flyToLocation: null,
  notificationPermission: typeof window !== 'undefined' && 'Notification' in window ? Notification.permission : 'default',
  bannerDismissed: getInitialBannerDismissed(),
  toggleDarkMode: () => set((state) => {
    const newMode = !state.darkMode;
    applyDarkClass(newMode);
    if (typeof window !== 'undefined') {
      localStorage.setItem('traveltrek-dark-mode', String(newMode));
    }
    return { darkMode: newMode };
  }),
  setRightPanelOpen: (isOpen) => set({ rightPanelOpen: isOpen }),
  addToast: (toast) => set((state) => ({
    toasts: [...state.toasts, { ...toast, id: crypto.randomUUID() }]
  })),
  removeToast: (id) => set((state) => ({
    toasts: state.toasts.filter((t) => t.id !== id)
  })),
  setConnectionStatus: (status) => set({ connectionStatus: status }),
  setFlyToLocation: (loc) => set({ flyToLocation: loc }),
  setNotificationPermission: (permission) => set({ notificationPermission: permission }),
  dismissBanner: () => set(() => {
    if (typeof window !== 'undefined') {
      localStorage.setItem('traveltrek-banner-dismissed', 'true');
    }
    return { bannerDismissed: true };
  })
}));
