import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface SettingsState {
  region: string;
  mapDefaultCenter: [number, number]; // [lng, lat]
  mapDefaultZoom: number;
  soundVolume: number; // 0.0 to 1.0
  notificationsEnabled: boolean;
  apiBaseUrl: string;
  operatorProfile: {
    name: string;
    role: string;
  };
  devModeEnabled: boolean;
  
  // Actions
  setRegion: (region: string) => void;
  setMapDefaults: (center: [number, number], zoom: number) => void;
  setSoundVolume: (volume: number) => void;
  setNotificationsEnabled: (enabled: boolean) => void;
  setApiBaseUrl: (url: string) => void;
  setOperatorProfile: (profile: { name: string; role: string }) => void;
  setDevModeEnabled: (enabled: boolean) => void;
  resetSettings: () => void;
}

const initialState = {
  region: 'pune',
  mapDefaultCenter: [73.8567, 18.5204] as [number, number], // Pune, India default
  mapDefaultZoom: 12,
  soundVolume: 0.8,
  notificationsEnabled: true,
  apiBaseUrl: import.meta.env.VITE_BACKEND_SOCKET_URL || 'http://localhost:3001',
  operatorProfile: {
    name: 'Officer Abhijeet',
    role: 'admin',
  },
  devModeEnabled: false,
};

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      ...initialState,
      setRegion: (region) => set({ region }),
      setMapDefaults: (mapDefaultCenter, mapDefaultZoom) => set({ mapDefaultCenter, mapDefaultZoom }),
      setSoundVolume: (soundVolume) => set({ soundVolume }),
      setNotificationsEnabled: (notificationsEnabled) => set({ notificationsEnabled }),
      setApiBaseUrl: (apiBaseUrl) => set({ apiBaseUrl }),
      setOperatorProfile: (operatorProfile) => set({ operatorProfile }),
      setDevModeEnabled: (devModeEnabled) => set({ devModeEnabled }),
      resetSettings: () => set(initialState),
    }),
    {
      name: 'travelsure-settings',
    }
  )
);

