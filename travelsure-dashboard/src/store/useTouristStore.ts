import { create } from 'zustand';

export interface Position {
  lat: number;
  lng: number;
}

export interface TouristPosition extends Position {
  id: string;
  lastUpdated: number;
  status: 'safe' | 'warning' | 'critical' | 'offline';
}

interface TouristState {
  positions: Record<string, TouristPosition>;
  selectedTourist: string | null;
  updatePosition: (id: string, position: Position, status?: 'safe' | 'warning' | 'critical' | 'offline') => void;
  selectTourist: (id: string | null) => void;
}

export const useTouristStore = create<TouristState>((set) => ({
  positions: {},
  selectedTourist: null,
  updatePosition: (id, position, status) => set((state) => {
    const existing = state.positions[id];
    return {
      positions: {
        ...state.positions,
        [id]: { 
          id, 
          ...position, 
          lastUpdated: Date.now(),
          status: status || existing?.status || 'safe'
        }
      }
    };
  }),
  selectTourist: (id) => set({ selectedTourist: id })
}));
