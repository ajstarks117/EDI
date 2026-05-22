import { create } from 'zustand';

export interface Alert {
  id: string;
  priority: 'P0' | 'P1' | 'P2' | 'P3' | 'P4';
  message: string;
  touristId?: string;
  timestamp: number;
  status: 'new' | 'acknowledged' | 'assigned' | 'escalated' | 'closed';
}

interface AlertState {
  alertFeed: Alert[];
  addAlert: (alert: Omit<Alert, 'id' | 'timestamp' | 'status'>) => void;
  updateAlert: (id: string, alert: Partial<Omit<Alert, 'id' | 'timestamp'>>) => void;
  removeAlert: (id: string) => void;
  clearAlerts: () => void;
}

const PRIORITY_MAP = { P0: 0, P1: 1, P2: 2, P3: 3, P4: 4 };

// Generate mock alerts for virtualization testing
const generateMockAlerts = (): Alert[] => {
  return Array.from({ length: 500 }).map((_, i) => ({
    id: `mock-alert-${i}`,
    priority: ['P0', 'P1', 'P2', 'P3', 'P4'][Math.floor(Math.random() * 5)] as Alert['priority'],
    message: `Auto-generated system alert #${i} for testing virtualization`,
    timestamp: Date.now() - Math.floor(Math.random() * 10000000),
    status: 'new' as Alert['status']
  })).sort((a, b) => {
    if (PRIORITY_MAP[a.priority] !== PRIORITY_MAP[b.priority]) {
      return PRIORITY_MAP[a.priority] - PRIORITY_MAP[b.priority];
    }
    return b.timestamp - a.timestamp;
  });
};

export const useAlertStore = create<AlertState>((set) => ({
  alertFeed: generateMockAlerts(),
  addAlert: (alert) => set((state) => {
    const newAlert: Alert = {
      ...alert,
      id: crypto.randomUUID(),
      timestamp: Date.now(),
      status: 'new'
    };
    const feed = [newAlert, ...state.alertFeed].sort((a, b) => {
      if (PRIORITY_MAP[a.priority] !== PRIORITY_MAP[b.priority]) {
        return PRIORITY_MAP[a.priority] - PRIORITY_MAP[b.priority];
      }
      return b.timestamp - a.timestamp;
    });
    return { alertFeed: feed };
  }),
  updateAlert: (id, updatedAlert) => set((state) => {
    const feed = state.alertFeed.map((a) => a.id === id ? { ...a, ...updatedAlert } : a).sort((a, b) => {
      if (PRIORITY_MAP[a.priority] !== PRIORITY_MAP[b.priority]) {
        return PRIORITY_MAP[a.priority] - PRIORITY_MAP[b.priority];
      }
      return b.timestamp - a.timestamp;
    });
    return { alertFeed: feed };
  }),
  removeAlert: (id) => set((state) => ({
    alertFeed: state.alertFeed.filter((a) => a.id !== id)
  })),
  clearAlerts: () => set({ alertFeed: [] })
}));
