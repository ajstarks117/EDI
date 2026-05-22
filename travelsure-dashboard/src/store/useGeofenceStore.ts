import { create } from 'zustand';

export interface Geofence {
  id: string;
  name: string;
  type: 'danger' | 'safe' | 'warning';
  coordinates: [number, number][]; // Polygon coordinates placeholder
}

interface GeofenceState {
  geofences: Geofence[];
  activeFilters: string[]; // e.g., ['danger', 'safe']
  setGeofences: (geofences: Geofence[]) => void;
  toggleFilter: (type: string) => void;
}

export const useGeofenceStore = create<GeofenceState>((set) => ({
  geofences: [],
  activeFilters: ['danger', 'safe', 'warning'],
  setGeofences: (geofences) => set({ geofences }),
  toggleFilter: (type) => set((state) => ({
    activeFilters: state.activeFilters.includes(type)
      ? state.activeFilters.filter((f) => f !== type)
      : [...state.activeFilters, type]
  }))
}));
