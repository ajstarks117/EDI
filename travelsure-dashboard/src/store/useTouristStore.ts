import { create } from 'zustand';

export interface Position {
  lat: number;
  lng: number;
}

export interface TouristPosition extends Position {
  id: string;
  lastUpdated: number;
}

interface TouristState {
  positions: Record<string, TouristPosition>;
  selectedTourist: string | null;
  updatePosition: (id: string, position: Position) => void;
  selectTourist: (id: string | null) => void;
}

export const useTouristStore = create<TouristState>((set) => ({
  positions: {},
  selectedTourist: null,
  updatePosition: (id, position) => set((state) => ({
    positions: {
      ...state.positions,
      [id]: { id, ...position, lastUpdated: Date.now() }
    }
  })),
  selectTourist: (id) => set({ selectedTourist: id })
}));
