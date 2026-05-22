import { create } from 'zustand';
import { useSettingsStore } from './useSettingsStore';

export interface Geofence {
  id: string;
  name: string;
  type: 'warning' | 'restricted' | 'exclusion';
  coordinates: [number, number][]; // Polygon coordinates
}

interface GeofenceState {
  geofences: Geofence[];
  activeFilters: string[]; 
  setGeofences: (geofences: Geofence[]) => void;
  addGeofence: (geofence: Geofence) => void;
  updateGeofence: (id: string, geofence: Partial<Geofence>) => void;
  deleteGeofence: (id: string) => void;
  toggleFilter: (type: string) => void;
}

export const useGeofenceStore = create<GeofenceState>((set) => ({
  geofences: [
    {
      id: 'mock-zone-1',
      name: 'Avalanche Risk Area',
      type: 'warning',
      coordinates: [[79.3200, 30.7300], [79.3300, 30.7300], [79.3300, 30.7400], [79.3200, 30.7400], [79.3200, 30.7300]]
    },
    {
      id: 'mock-zone-2',
      name: 'Military Base Perimeter',
      type: 'exclusion',
      coordinates: [[79.3100, 30.7100], [79.3150, 30.7100], [79.3150, 30.7150], [79.3100, 30.7150], [79.3100, 30.7100]]
    }
  ],
  activeFilters: ['warning', 'restricted', 'exclusion'],
  setGeofences: (geofences) => set({ geofences }),
  addGeofence: (geofence) => {
    const role = useSettingsStore.getState().operatorProfile.role;
    if (role !== 'admin') {
      console.warn('API BLOCKED: Unauthorized to create geofence');
      return;
    }
    set((state) => ({ geofences: [...state.geofences, geofence] }));
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
