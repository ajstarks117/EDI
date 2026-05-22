import { useEffect, useRef } from 'react';
import { io, Socket } from 'socket.io-client';
import { useAlertStore } from '../store/useAlertStore';
import { useTouristStore } from '../store/useTouristStore';
import { useUIStore } from '../store/useUIStore';
import { useSettingsStore } from '../store/useSettingsStore';

// Create a singleton socket instance outside the hook
// It's configured to not connect automatically so we can control it in the hook.
const SOCKET_URL = import.meta.env.VITE_BACKEND_SOCKET_URL || 'http://localhost:3001';

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

      socket.on('alert:new', (data: { priority: 'P0'|'P1'|'P2'|'P3'|'P4'; message: string; touristId?: string; lat?: number; lng?: number; id?: string }) => {
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

            // Fly to tourist's position — check positions cache first, fall back to alert coordinates
            let didFly = false;
            if (data.touristId) {
              const positions = useTouristStore.getState().positions;
              if (positions[data.touristId]) {
                const pos = positions[data.touristId];
                setFlyToLocation([pos.lng, pos.lat]);
                setRightPanelOpen(true);
                useTouristStore.getState().selectTourist(data.touristId);
                didFly = true;
              }
            }
            // If tourist not in cache, use alert's own lat/lng from the SOS payload
            if (!didFly && data.lat != null && data.lng != null) {
              setFlyToLocation([data.lng, data.lat]);
              setRightPanelOpen(true);
              // Also add the tourist to positions so they appear on the map
              if (data.touristId) {
                const tStore = useTouristStore.getState();
                tStore.updatePosition(data.touristId, { lat: data.lat, lng: data.lng }, 'critical');
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

      socket.on('zone:activated', (data: { name: string; type: string; zone?: any; action?: string }) => {
        if (data?.name) {
          addToast({
            message: `Geofence zone ${data.action === 'update' ? 'updated' : 'activated'}: ${data.name}`,
            type: data.type === 'danger' ? 'error' : 'info'
          });

          // Also add/update the zone in the geofence store for map rendering
          if (data.zone) {
            const { useGeofenceStore } = require('../store/useGeofenceStore');
            const store = useGeofenceStore.getState();
            const newZone = {
              id: data.zone.id?.toString() || crypto.randomUUID(),
              name: data.zone.name || data.name,
              type: (data.zone.zone_type || data.zone.zoneType || 'warning') as 'warning' | 'restricted' | 'exclusion',
              coordinates: data.zone.polygonCoordinates || data.zone.polygon_coordinates || data.zone.coordinates || [],
            };
            if (data.action === 'update') {
              store.updateGeofence(newZone.id, newZone);
            } else {
              store.addGeofence(newZone);
            }
          }
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
