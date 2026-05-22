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
  toggleDarkMode: () => void;
  setRightPanelOpen: (isOpen: boolean) => void;
  addToast: (toast: Omit<Toast, 'id'>) => void;
  removeToast: (id: string) => void;
  setConnectionStatus: (status: 'connected' | 'connecting' | 'disconnected') => void;
  setFlyToLocation: (loc: [number, number] | null) => void;
}

// Initial dark mode check, guarding against SSR
const getInitialDarkMode = () => {
  if (typeof window !== 'undefined') {
    return document.documentElement.classList.contains('dark') || 
           window.matchMedia('(prefers-color-scheme: dark)').matches || 
           true; // Ops dashboards default to true
  }
  return true;
};

export const useUIStore = create<UIState>((set) => ({
  darkMode: getInitialDarkMode(),
  rightPanelOpen: false,
  toasts: [],
  connectionStatus: 'disconnected',
  flyToLocation: null,
  toggleDarkMode: () => set((state) => {
    const newMode = !state.darkMode;
    if (typeof window !== 'undefined') {
      if (newMode) {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
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
  setFlyToLocation: (loc) => set({ flyToLocation: loc })
}));
