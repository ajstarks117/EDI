import { create } from 'zustand';

export interface Position {
  lat: number;
  lng: number;
}

export interface EmergencyContact {
  name: string;
  phone: string;
  relation: string;
}

export interface Tourist {
  id: string;
  tourist_id: string;
  lat: number;
  lng: number;
  lastUpdated: number;
  status: 'safe' | 'warning' | 'critical' | 'offline';
  trail: [number, number][]; // [lng, lat] pairs for mapping
  // Profile fields from registration
  name?: string;
  phone?: string;
  photo?: string;
  nationality?: string;
  id_document_type?: string;
  blood_group?: string;
  medical_conditions?: string;
  region_code?: string;
  languages?: string[];
  emergencyContact?: string;
  emergency_contacts?: EmergencyContact[];
  medicalInfo?: {
    bloodType: string;
    allergies: string[];
    conditions: string[];
    medications: string[];
  };
  isIdentityVerified?: boolean;
  is_active?: boolean;
  created_at?: string;
}

interface TouristState {
  positions: Record<string, Tourist>;
  registryTourists: Tourist[];
  selectedTourist: string | null;
  isLoading: boolean;
  error: string | null;
  initializeData: () => Promise<void>;
  fetchRegistry: () => Promise<void>;
  updatePosition: (id: string, position: { lat: number; lng: number }, status?: Tourist['status']) => void;
  bulkUpdatePositions: (updates: Record<string, { lat: number; lng: number; status?: Tourist['status'] }>) => void;
  selectTourist: (id: string | null) => void;
  setIdentityVerified: (id: string, verified: boolean) => void;
}

const MOCK_PROFILE_DATA = {
  name: 'Alex Mercer',
  photo: 'https://i.pravatar.cc/150?u=alex',
  nationality: 'Canadian',
  languages: ['English', 'French'],
  emergencyContact: '+1 555-0198 (Sarah Mercer)',
  medicalInfo: {
    bloodType: 'O-',
    allergies: ['Penicillin', 'Peanuts'],
    conditions: ['Asthma'],
    medications: ['Albuterol Inhaler']
  },
  isIdentityVerified: false
};

const INITIAL_MOCK_POSITIONS = {
  't-101': { id: 't-101', tourist_id: 't-101', lat: 30.7352, lng: 79.3235, lastUpdated: Date.now(), status: 'safe', trail: [[79.3200, 30.7300], [79.3235, 30.7352]], ...MOCK_PROFILE_DATA, name: 'John Doe', photo: 'https://i.pravatar.cc/150?u=john' },
  't-102': { id: 't-102', tourist_id: 't-102', lat: 30.7400, lng: 79.3300, lastUpdated: Date.now(), status: 'warning', trail: [[79.3350, 30.7450], [79.3300, 30.7400]], ...MOCK_PROFILE_DATA, name: 'Alice Smith', photo: 'https://i.pravatar.cc/150?u=alice' },
  't-103': { id: 't-103', tourist_id: 't-103', lat: 30.7200, lng: 79.3100, lastUpdated: Date.now(), status: 'critical', trail: [[79.3150, 30.7250], [79.3100, 30.7200]], ...MOCK_PROFILE_DATA, name: 'Carlos Ray', photo: 'https://i.pravatar.cc/150?u=carlos' },
  't-104': { id: 't-104', tourist_id: 't-104', lat: 30.7500, lng: 79.3500, lastUpdated: Date.now() - 3600000, status: 'offline', trail: [], ...MOCK_PROFILE_DATA, name: 'Emma Watson', photo: 'https://i.pravatar.cc/150?u=emma' }
} as Record<string, Tourist>;

export const useTouristStore = create<TouristState>((set) => ({
  positions: {},
  registryTourists: [],
  selectedTourist: null,
  isLoading: false,
  error: null,

  /**
   * Fetch registered tourists from /api/tourists/registry for the Tourist Registry page.
   * Response shape: { success: true, data: { tourists: [...], total: N } }
   */
  fetchRegistry: async () => {
    set({ isLoading: true, error: null });
    try {
      const { useSettingsStore } = await import('./useSettingsStore');
      const { apiBaseUrl } = useSettingsStore.getState();
      const res = await fetch(`${apiBaseUrl}/api/tourists/registry`, {
        headers: { 'Content-Type': 'application/json' },
      });
      if (res.ok) {
        const json = await res.json();
        const tourists: Tourist[] = (json.data?.tourists || json.tourists || []).map((t: any) => {
          const id = t.tourist_id || t.id;

          // Parse medical info
          let medicalInfo = {
            bloodType: t.blood_group || 'Unknown',
            allergies: [] as string[],
            conditions: [] as string[],
            medications: [] as string[],
          };
          if (t.medical_conditions) {
            try {
              const parsed = JSON.parse(t.medical_conditions);
              medicalInfo = { ...medicalInfo, ...parsed };
            } catch {
              if (t.medical_conditions !== 'None' && t.medical_conditions.trim()) {
                medicalInfo.conditions.push(t.medical_conditions);
              }
            }
          }

          return {
            id: t.id,
            tourist_id: id,
            lat: t.last_lat ?? t.lat ?? 18.5204,
            lng: t.last_lng ?? t.lng ?? 73.8567,
            lastUpdated: new Date(t.created_at || Date.now()).getTime(),
            status: t.is_active ? 'safe' : 'offline',
            trail: [],
            name: t.full_name || t.name,
            phone: t.phone,
            photo: t.profile_photo_url || `https://i.pravatar.cc/150?u=${id}`,
            nationality: t.nationality,
            id_document_type: t.id_document_type,
            blood_group: t.blood_group,
            medical_conditions: t.medical_conditions,
            region_code: t.region_code,
            languages: t.languages || [],
            emergencyContact: t.phone,
            emergency_contacts: t.emergency_contacts || [],
            medicalInfo,
            isIdentityVerified: !!t.identity_hash || !!t.is_identity_verified,
            is_active: t.is_active,
            created_at: t.created_at,
          } as Tourist;
        });

        set({ registryTourists: tourists, isLoading: false, error: null });

        // Also populate positions map for other pages (Map, etc.)
        if (tourists.length > 0) {
          const positions: Record<string, Tourist> = {};
          for (const t of tourists) {
            positions[t.tourist_id] = t;
          }
          set({ positions });
        }
        return;
      }
    } catch (err) {
      console.warn('[tourists] Registry fetch failed:', err);
    }
    set({ registryTourists: [], isLoading: false });
  },

  initializeData: async () => {
    set({ isLoading: true, error: null });
    try {
      const { useSettingsStore } = await import('./useSettingsStore');
      const { apiBaseUrl } = useSettingsStore.getState();
      const res = await fetch(`${apiBaseUrl}/api/tourists/registry`, {
        headers: { 'Content-Type': 'application/json' },
      });
      if (res.ok) {
        const json = await res.json();
        const touristsList = json.data?.tourists || json.tourists || [];
        const positions: Record<string, Tourist> = {};
        for (const t of touristsList) {
          const id = t.tourist_id || t.id;
          positions[id] = {
            id: t.id,
            tourist_id: id,
            lat: t.last_lat ?? t.lat ?? 18.5204,
            lng: t.last_lng ?? t.lng ?? 73.8567,
            lastUpdated: new Date(t.created_at || Date.now()).getTime(),
            status: t.is_active ? 'safe' : 'offline',
            trail: [],
            name: t.full_name || t.name,
            phone: t.phone,
            photo: t.profile_photo_url || `https://i.pravatar.cc/150?u=${id}`,
            nationality: t.nationality,
            languages: t.languages || [],
            emergencyContact: t.phone,
            isIdentityVerified: !!t.identity_hash || !!t.is_identity_verified,
            is_active: t.is_active,
            created_at: t.created_at,
          };
        }
        if (Object.keys(positions).length > 0) {
          set({ positions, registryTourists: Object.values(positions), isLoading: false });
          return;
        }
      }
    } catch (err) {
      console.warn('[tourists] Backend fetch failed, using mock data:', err);
    }

    // Fallback: use mock positions
    set({ positions: INITIAL_MOCK_POSITIONS, registryTourists: Object.values(INITIAL_MOCK_POSITIONS), isLoading: false });
  },
  updatePosition: (id, position, status) => set((state) => {
    const existing = state.positions[id];
    if (!existing) return state;
    
    // Update trail (keep last 10 points)
    const newTrail = [...existing.trail, [position.lng, position.lat] as [number, number]];
    if (newTrail.length > 10) newTrail.shift();

    return {
      positions: {
        ...state.positions,
        [id]: {
          ...existing,
          lat: position.lat,
          lng: position.lng,
          lastUpdated: Date.now(),
          status: status || existing.status,
          trail: newTrail
        }
      }
    };
  }),
  bulkUpdatePositions: (updates) => set((state) => {
    const newPositions = { ...state.positions };
    const now = Date.now();
    for (const [id, update] of Object.entries(updates)) {
      const existing = newPositions[id];
      if (!existing) continue;
      const newTrail = [...existing.trail, [update.lng, update.lat] as [number, number]];
      if (newTrail.length > 10) newTrail.shift();
      newPositions[id] = {
        ...existing,
        lat: update.lat,
        lng: update.lng,
        lastUpdated: now,
        status: update.status || existing.status,
        trail: newTrail,
      };
    }
    return { positions: newPositions };
  }),
  selectTourist: (id) => set({ selectedTourist: id }),
  setIdentityVerified: (id, verified) => set((state) => ({
    positions: {
      ...state.positions,
      [id]: { ...state.positions[id], isIdentityVerified: verified }
    }
  }))
}));
