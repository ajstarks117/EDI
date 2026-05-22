import { create } from 'zustand';
import { useSettingsStore } from './useSettingsStore';

export interface Geofence {
  id: string;
  name: string;
  type: 'warning' | 'restricted' | 'exclusion';
  coordinates: [number, number][]; // Polygon coordinates [lng, lat]
  advisoryText?: string;
}

interface GeofenceState {
  geofences: Geofence[];
  activeFilters: string[]; 
  isLoading: boolean;
  setGeofences: (geofences: Geofence[]) => void;
  addGeofence: (geofence: Geofence) => void;
  updateGeofence: (id: string, geofence: Partial<Geofence>) => void;
  deleteGeofence: (id: string) => void;
  toggleFilter: (type: string) => void;
  initializeData: () => Promise<void>;
}

const MOCK_GEOFENCES: Geofence[] = [
  {
    id: 'mock-zone-1',
    name: 'Avalanche Risk Area',
    type: 'warning',
    coordinates: [[73.8400, 18.5100], [73.8500, 18.5100], [73.8500, 18.5200], [73.8400, 18.5200], [73.8400, 18.5100]]
  },
  {
    id: 'mock-zone-2',
    name: 'Military Base Perimeter',
    type: 'exclusion',
    coordinates: [[73.8600, 18.5300], [73.8650, 18.5300], [73.8650, 18.5350], [73.8600, 18.5350], [73.8600, 18.5300]]
  }
];

export const useGeofenceStore = create<GeofenceState>((set) => ({
  geofences: [],
  activeFilters: ['warning', 'restricted', 'exclusion'],
  isLoading: false,

  initializeData: async () => {
    set({ isLoading: true });
    try {
      const { apiBaseUrl } = useSettingsStore.getState();
      const res = await fetch(`${apiBaseUrl}/api/geofence/zones`, {
        headers: { 'Content-Type': 'application/json' },
      });
      if (res.ok) {
        const json = await res.json();
        const rawZones = json.data?.zones || json.zones || json.data || [];
        const geofences: Geofence[] = rawZones.map((z: any) => ({
          id: z.id?.toString() || crypto.randomUUID(),
          name: z.name || 'Unknown Zone',
          type: (z.zone_type || z.zoneType || 'warning') as Geofence['type'],
          coordinates: z.polygonCoordinates || z.polygon_coordinates || z.coordinates || [],
          advisoryText: z.advisory_text || z.advisoryText || '',
        }));
        if (geofences.length > 0) {
          set({ geofences, isLoading: false });
          return;
        }
      }
    } catch (err) {
      console.warn('[geofence] Backend fetch failed, using mock data:', err);
    }

    // Fallback to mock
    set({ geofences: MOCK_GEOFENCES, isLoading: false });
  },

  setGeofences: (geofences) => set({ geofences }),

  addGeofence: async (geofence) => {
    const role = useSettingsStore.getState().operatorProfile.role;
    if (role !== 'admin') {
      console.warn('API BLOCKED: Unauthorized to create geofence');
      return;
    }

    // Optimistically add to local state
    set((state) => ({ geofences: [...state.geofences, geofence] }));

    // Persist to backend
    try {
      const { apiBaseUrl } = useSettingsStore.getState();
      await fetch(`${apiBaseUrl}/api/geofence/zones`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: geofence.name,
          zone_type: geofence.type,
          polygon_coordinates: geofence.coordinates,
          advisory_text: geofence.advisoryText || '',
        }),
      });
    } catch (err) {
      console.warn('[geofence] Backend POST failed (saved locally):', err);
    }
  },

  updateGeofence: (id, updated) => set((state) => ({
    geofences: state.geofences.map(g => g.id === id ? { ...g, ...updated } : g)
  })),

  deleteGeofence: (id) => {
    const role = useSettingsStore.getState().operatorProfile.role;
    if (role !== 'admin') {
      console.warn('API BLOCKED: Unauthorized to delete geofence');
      return;
    }
    set((state) => ({
      geofences: state.geofences.filter(g => g.id !== id)
    }));
  },

  toggleFilter: (type) => set((state) => ({
    activeFilters: state.activeFilters.includes(type)
      ? state.activeFilters.filter((f) => f !== type)
      : [...state.activeFilters, type]
  }))
}));
