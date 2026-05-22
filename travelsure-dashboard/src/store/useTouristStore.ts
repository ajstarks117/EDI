import { create } from 'zustand';

export interface Position {
  lat: number;
  lng: number;
}

export interface TouristPosition extends Position {
  id: string;
  lastUpdated: number;
  status: 'safe' | 'warning' | 'critical' | 'offline';
  trail: [number, number][];
}

interface TouristState {
  positions: Record<string, TouristPosition>;
  selectedTourist: string | null;
  updatePosition: (id: string, position: Position, status?: 'safe' | 'warning' | 'critical' | 'offline') => void;
  selectTourist: (id: string | null) => void;
}

export const useTouristStore = create<TouristState>((set) => ({
  positions: {
    't-101': { id: 't-101', lat: 30.7352, lng: 79.3235, lastUpdated: Date.now(), status: 'safe', trail: [[79.3200, 30.7300], [79.3235, 30.7352]] },
    't-102': { id: 't-102', lat: 30.7400, lng: 79.3300, lastUpdated: Date.now(), status: 'warning', trail: [[79.3350, 30.7450], [79.3300, 30.7400]] },
    't-103': { id: 't-103', lat: 30.7200, lng: 79.3100, lastUpdated: Date.now(), status: 'critical', trail: [[79.3150, 30.7250], [79.3100, 30.7200]] },
    't-104': { id: 't-104', lat: 30.7500, lng: 79.3500, lastUpdated: Date.now() - 3600000, status: 'offline', trail: [] }
  },
  selectedTourist: null,
  updatePosition: (id, position, status) => set((state) => {
    const existing = state.positions[id];
    const newPoint: [number, number] = [position.lng, position.lat];
    const oldTrail = existing?.trail || [];
    const trail = [...oldTrail, newPoint].slice(-10);

    return {
      positions: {
        ...state.positions,
        [id]: { 
          id, 
          ...position, 
          lastUpdated: Date.now(),
          status: status || existing?.status || 'safe',
          trail
        }
      }
    };
  }),
  selectTourist: (id) => set({ selectedTourist: id })
}));
