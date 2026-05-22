import { useEffect, useRef } from 'react';
import { io, Socket } from 'socket.io-client';
import { useAlertStore } from '../store/useAlertStore';
import { useTouristStore } from '../store/useTouristStore';
import { useUIStore } from '../store/useUIStore';

// Create a singleton socket instance outside the hook
// It's configured to not connect automatically so we can control it in the hook.
const SOCKET_URL = import.meta.env.VITE_BACKEND_SOCKET_URL || 'http://localhost:4000';

export const socket: Socket = io(SOCKET_URL, {
  autoConnect: false,
  reconnection: true,
  reconnectionDelay: 1000,
  reconnectionDelayMax: 5000,
  reconnectionAttempts: Infinity,
});

export function useWebSocket() {
  const { addAlert, updateAlert } = useAlertStore();
  const { updatePosition } = useTouristStore();
  const { setConnectionStatus, addToast } = useUIStore();
  
  // Ref to track if we've initialized listeners to prevent duplicates in strict mode
  const initialized = useRef(false);

  useEffect(() => {
    if (!initialized.current) {
      initialized.current = true;

      // Connection state listeners
      socket.on('connect', () => {
        setConnectionStatus('connected');
      });

      socket.on('disconnect', (reason) => {
        setConnectionStatus(reason === 'io client disconnect' ? 'disconnected' : 'connecting');
      });

      socket.on('connect_error', () => {
        setConnectionStatus('connecting');
      });

      // Domain event listeners
      socket.on('tourist:location', (data: { id: string; lat: number; lng: number; status?: 'safe' | 'warning' | 'critical' | 'offline' }) => {
        if (data?.id && data?.lat != null && data?.lng != null) {
          updatePosition(data.id, { lat: data.lat, lng: data.lng }, data.status);
        }
      });

      socket.on('alert:new', (data: { type: 'critical' | 'warning' | 'info'; message: string; touristId?: string }) => {
        if (data?.type && data?.message) {
          addAlert(data);
        }
      });

      socket.on('alert:updated', (data: { id: string; type?: 'critical' | 'warning' | 'info'; message?: string }) => {
        if (data?.id) {
          updateAlert(data.id, data);
        }
      });

      socket.on('zone:activated', (data: { name: string; type: string }) => {
        if (data?.name) {
          addToast({
            message: `Geofence zone activated: ${data.name}`,
            type: data.type === 'danger' ? 'error' : 'info'
          });
        }
      });

      socket.connect();
    }

    return () => {
      // Clean up event listeners on unmount
      socket.off('connect');
      socket.off('disconnect');
      socket.off('connect_error');
      socket.off('tourist:location');
      socket.off('alert:new');
      socket.off('alert:updated');
      socket.off('zone:activated');
      // We don't disconnect the socket here if we want to keep it alive across navigation,
      // but if the hook is only used in a top-level component (like Layout), it will only unmount on app close.
      // If we need to strictly manage it, we can call socket.disconnect(), but usually we want it to persist.
      initialized.current = false;
    };
  }, [addAlert, updateAlert, updatePosition, setConnectionStatus, addToast]);

  return socket;
}
