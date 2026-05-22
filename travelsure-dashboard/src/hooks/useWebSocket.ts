import { useEffect, useRef } from 'react';
import { io, Socket } from 'socket.io-client';
import { useAlertStore } from '../store/useAlertStore';
import { useTouristStore } from '../store/useTouristStore';
import { useUIStore } from '../store/useUIStore';
import { useSettingsStore } from '../store/useSettingsStore';

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
  const { bulkUpdatePositions } = useTouristStore();
  const { setConnectionStatus, addToast, setFlyToLocation, setRightPanelOpen } = useUIStore();
  
  // Ref to track if we've initialized listeners to prevent duplicates in strict mode
  const initialized = useRef(false);
  // Location event buffer – accumulates updates, flushed every 250ms
  const locationBuffer = useRef<Record<string, { lat: number; lng: number; status?: 'safe' | 'warning' | 'critical' | 'offline' }>>({});
  const flushInterval = useRef<ReturnType<typeof setInterval> | null>(null);

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

      // Buffered location handler – accumulate into buffer, overwrite per-tourist
      socket.on('tourist:location', (data: { id: string; lat: number; lng: number; status?: 'safe' | 'warning' | 'critical' | 'offline' }) => {
        if (data?.id && data?.lat != null && data?.lng != null) {
          locationBuffer.current[data.id] = { lat: data.lat, lng: data.lng, status: data.status };
        }
      });

      // Flush the location buffer every 250ms
      flushInterval.current = setInterval(() => {
        const buf = locationBuffer.current;
        if (Object.keys(buf).length > 0) {
          bulkUpdatePositions(buf);
          locationBuffer.current = {};
        }
      }, 250);

      socket.on('alert:new', (data: { priority: 'P0'|'P1'|'P2'|'P3'|'P4'; message: string; touristId?: string }) => {
        if (data?.priority && data?.message) {
          addAlert(data);
          if (data.priority === 'P0') {
            addToast({ message: `SOS CRITICAL: ${data.message}`, type: 'error' });
            
            const { soundVolume, notificationsEnabled } = useSettingsStore.getState();

            // Play synthetic distinct tone using Web Audio API
            if (soundVolume > 0) {
              try {
                const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
                const oscillator = audioCtx.createOscillator();
                const gainNode = audioCtx.createGain();
                
                oscillator.type = 'square';
                oscillator.frequency.setValueAtTime(880, audioCtx.currentTime); // A5 beep
                oscillator.frequency.exponentialRampToValueAtTime(440, audioCtx.currentTime + 0.2);
                
                gainNode.gain.setValueAtTime(soundVolume, audioCtx.currentTime);
                gainNode.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.5);
                
                oscillator.connect(gainNode);
                gainNode.connect(audioCtx.destination);
                
                oscillator.start();
                oscillator.stop(audioCtx.currentTime + 0.5);
              } catch (e) {
                console.warn('Web Audio API play blocked:', e);
              }
            }

            // Trigger Browser Notification
            if (notificationsEnabled && typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'granted') {
              new Notification('⚠️ P0 SOS ALERT', {
                body: data.message,
                requireInteraction: true,
              });
            }

            if (data.touristId) {
              const positions = useTouristStore.getState().positions;
              if (positions[data.touristId]) {
                const pos = positions[data.touristId];
                setFlyToLocation([pos.lng, pos.lat]);
                setRightPanelOpen(true);
                useTouristStore.getState().selectTourist(data.touristId);
              }
            }
          }
        }
      });

      socket.on('alert:updated', (data: { id: string; priority?: 'P0'|'P1'|'P2'|'P3'|'P4'; message?: string; status?: 'new'|'acknowledged'|'assigned'|'escalated'|'closed' }) => {
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
      if (flushInterval.current) {
        clearInterval(flushInterval.current);
      }
      initialized.current = false;
    };
  }, [addAlert, updateAlert, bulkUpdatePositions, setConnectionStatus, addToast]);

  const { apiBaseUrl, region } = useSettingsStore();

  // Reconnect when API Base URL changes
  useEffect(() => {
    const ioManager = socket.io as any;
    if (ioManager.uri !== apiBaseUrl) {
      ioManager.uri = apiBaseUrl;
      if (socket.connected) {
        socket.disconnect();
        socket.connect();
      }
    }
  }, [apiBaseUrl]);

  // Handle region subscription when region changes or socket connects
  useEffect(() => {
    const handleConnect = () => {
      socket.emit('subscribe:region', { region });
    };

    if (socket.connected) {
      socket.emit('subscribe:region', { region });
    }

    socket.on('connect', handleConnect);
    return () => {
      socket.off('connect', handleConnect);
    };
  }, [region]);

  return socket;
}
