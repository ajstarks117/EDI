import { create } from 'zustand';
import { useTouristStore } from './useTouristStore';
import { useAlertStore } from './useAlertStore';

export interface DemoStep {
  title: string;
  description: string;
  target?: string; // CSS Selector to highlight if applicable
  badge?: string;
}

interface DemoState {
  enabled: boolean;
  currentStep: number;
  simulatedAlertId: string | null;
  toggle: () => void;
  nextStep: () => void;
  prevStep: () => void;
  setStep: (index: number) => void;
  triggerSimulatedSos: () => void;
  resetDemo: () => void;
  steps: DemoStep[];
}

export const useDemoStore = create<DemoState>((set, get) => ({
  enabled: false,
  currentStep: 0,
  simulatedAlertId: null,
  steps: [
    {
      title: "Act 1: Normal System Monitoring",
      description: "Welcome to the SIH-25002 Demo. Currently, the system is in normal operation. Tourists are tracked in real-time on the map using GPS/Satellite telemetry, and geofence restrictions (warning, restricted, exclusion zones) protect critical areas.",
      badge: "Normal Operations"
    },
    {
      title: "Act 2: Distress Scenario (SOS Triggered)",
      description: "In deep valley regions, GPS and GSM cell networks fail. Click 'Trigger SOS' below to simulate a tourist triggering a panic distress message. The system will leverage a BLE (Bluetooth Low Energy) relay mesh network to route the signal.",
      badge: "Distress Simulation",
      target: "#simulate-sos-btn"
    },
    {
      title: "Act 3: BLE Relay & Multi-Hop Mesh Network",
      description: "Look at the Active Incident card! The SOS was successfully routed through neighboring tourist Alice Smith (t-102) and a stationary BLE Hub to bypass cellular blackouts. Hover over or review the hops in the incident profile details.",
      badge: "Mesh Networks",
      target: "#ble-mesh-indicator"
    },
    {
      title: "Act 4: Operator Dispatch & Verification",
      description: "As the operator, you now verify the tourist's profile, including secure blockchain-verified identity and gated medical credentials. You can dispatch rescue teams, sync safety contracts, or resolve the issue.",
      badge: "Emergency Dispatch"
    }
  ],
  toggle: () => {
    const isEnabling = !get().enabled;
    if (!isEnabling) {
      get().resetDemo();
    }
    set({ enabled: isEnabling });
  },
  nextStep: () => {
    const { currentStep, steps } = get();
    if (currentStep < steps.length - 1) {
      set({ currentStep: currentStep + 1 });
    }
  },
  prevStep: () => {
    const { currentStep } = get();
    if (currentStep > 0) {
      set({ currentStep: currentStep - 1 });
    }
  },
  setStep: (index) => {
    set({ currentStep: index });
  },
  triggerSimulatedSos: () => {
    const touristStore = useTouristStore.getState();
    const alertStore = useAlertStore.getState();

    // 1. Set t-101 (John Doe) to critical
    touristStore.updatePosition('t-101', { lat: 30.7352, lng: 79.3235 }, 'critical');

    // 2. Select t-101 to pop open the sidebar
    touristStore.selectTourist('t-101');

    // 3. Add a critical P0 alert for t-101
    const alertId = crypto.randomUUID();
    
    // Directly inject to store feed
    alertStore.addAlert({
      priority: 'P0',
      message: 'CRITICAL: BLE Mesh Distress SOS triggered by Alex Mercer (t-101)',
      touristId: 't-101'
    });

    // Move to Act 3 automatically
    set({ 
      simulatedAlertId: alertId,
      currentStep: 2
    });
  },
  resetDemo: () => {
    const touristStore = useTouristStore.getState();
    const alertStore = useAlertStore.getState();

    // Reset tourist t-101 back to safe
    touristStore.updatePosition('t-101', { lat: 30.7352, lng: 79.3235 }, 'safe');
    touristStore.selectTourist(null);

    // Filter out mock P0 alert for t-101
    alertStore.clearAlerts();
    alertStore.initializeData();

    set({ 
      currentStep: 0,
      simulatedAlertId: null
    });
  }
}));
