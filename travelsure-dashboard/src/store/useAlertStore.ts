import { create } from 'zustand';

export interface Alert {
  id: string;
  type: 'critical' | 'warning' | 'info';
  message: string;
  touristId?: string;
  timestamp: number;
}

interface AlertState {
  alertFeed: Alert[];
  addAlert: (alert: Omit<Alert, 'id' | 'timestamp'>) => void;
  removeAlert: (id: string) => void;
  clearAlerts: () => void;
}

export const useAlertStore = create<AlertState>((set) => ({
  alertFeed: [],
  addAlert: (alert) => set((state) => ({
    alertFeed: [{
      ...alert,
      id: crypto.randomUUID(),
      timestamp: Date.now()
    }, ...state.alertFeed]
  })),
  removeAlert: (id) => set((state) => ({
    alertFeed: state.alertFeed.filter((a) => a.id !== id)
  })),
  clearAlerts: () => set({ alertFeed: [] })
}));
