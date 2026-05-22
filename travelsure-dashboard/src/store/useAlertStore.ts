import { create } from 'zustand';
import { useSettingsStore } from './useSettingsStore';

export interface Alert {
  id: string;
  priority: 'P0' | 'P1' | 'P2' | 'P3' | 'P4';
  message: string;
  touristId?: string;
  timestamp: number;
  status: 'new' | 'acknowledged' | 'assigned' | 'escalated' | 'closed';
  resolutionNotes?: string;
}

interface AlertState {
  alertFeed: Alert[];
  isLoading: boolean;
  error: string | null;
  addAlert: (alert: Omit<Alert, 'id' | 'timestamp' | 'status'>) => void;
  updateAlert: (id: string, alert: Partial<Omit<Alert, 'id' | 'timestamp'>>) => void;
  removeAlert: (id: string) => void;
  clearAlerts: () => void;
  initializeData: () => Promise<void>;
}

const PRIORITY_MAP = { P0: 0, P1: 1, P2: 2, P3: 3, P4: 4 };

// Generate mock alerts for virtualization testing
const generateMockAlerts = (): Alert[] => {
  return Array.from({ length: 50 }).map((_, i) => ({ // reduced length for realism
    id: `mock-alert-${i}`,
    priority: ['P0', 'P1', 'P2', 'P3', 'P4'][Math.floor(Math.random() * 5)] as Alert['priority'],
    message: `System incident report #${i}`,
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
  alertFeed: [],
  isLoading: false,
  error: null,
  initializeData: async () => {
    set({ isLoading: true, error: null });
    try {
      const { fetchWithRetry } = await import('../utils/fetchWithRetry');
      
      const mockFetch = async () => {
        return new Promise<Alert[]>((resolve, reject) => {
          setTimeout(() => {
            // Simulate 10% failure rate for testing retries
            if (Math.random() < 0.1) {
              reject(new Error('Simulated network failure'));
            } else {
              resolve(generateMockAlerts());
            }
          }, 1500); // 1.5s delay to show skeletons
        });
      };

      const data = await fetchWithRetry(mockFetch, { 
        maxRetries: 3, 
        errorContext: 'Alert Feed Data' 
      });

      set({ alertFeed: data, isLoading: false });
    } catch (err) {
      set({ 
        error: err instanceof Error ? err.message : 'Failed to fetch alerts', 
        isLoading: false 
      });
    }
  },
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
  updateAlert: (id, updatedAlert) => {
    if (updatedAlert.status) {
      const role = useSettingsStore.getState().operatorProfile.role;
      if (role !== 'admin' && role !== 'dispatcher') {
        console.warn('API BLOCKED: Unauthorized to manage alerts');
        return;
      }
    }
    set((state) => {
      const feed = state.alertFeed.map((a) => a.id === id ? { ...a, ...updatedAlert } : a).sort((a, b) => {
        if (PRIORITY_MAP[a.priority] !== PRIORITY_MAP[b.priority]) {
          return PRIORITY_MAP[a.priority] - PRIORITY_MAP[b.priority];
        }
        return b.timestamp - a.timestamp;
      });
      return { alertFeed: feed };
    });
  },
  removeAlert: (id) => set((state) => ({
    alertFeed: state.alertFeed.filter((a) => a.id !== id)
  })),
  clearAlerts: () => set({ alertFeed: [] })
}));
