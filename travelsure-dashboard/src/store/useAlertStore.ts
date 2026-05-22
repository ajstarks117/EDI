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
      const { apiBaseUrl } = useSettingsStore.getState();
      const res = await fetch(`${apiBaseUrl}/api/alerts?limit=50`, {
        headers: { 'Content-Type': 'application/json' },
      });
      if (res.ok) {
        const json = await res.json();
        const backendAlerts = (json.data?.alerts || json.alerts || []).map((a: any) => ({
          id: a.id,
          priority: a.priority === 'critical' ? 'P0' : a.priority === 'high' ? 'P1' : a.priority === 'medium' ? 'P2' : 'P3',
          message: a.message || `SOS from ${a.tourist_name || 'Tourist'} at (${a.lat}, ${a.lng})`,
          touristId: a.tourist_id || a.tourist_ref_id,
          timestamp: new Date(a.created_at || Date.now()).getTime(),
          status: a.status === 'active' ? 'new' : a.status as Alert['status'],
        }));
        set({ alertFeed: backendAlerts, isLoading: false });
        return;
      }
    } catch (err) {
      console.warn('[alerts] Backend fetch failed, using mock data:', err);
    }

    // Fallback: generate mock alerts
    try {
      const data = generateMockAlerts();
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
