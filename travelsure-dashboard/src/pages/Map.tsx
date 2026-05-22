import { useEffect, useRef, useState, useCallback } from 'react';
import { GoogleMap, useJsApiLoader, MarkerF, PolylineF, PolygonF, DrawingManagerF } from '@react-google-maps/api';
import { useTouristStore } from '../store/useTouristStore';
import { useUIStore } from '../store/useUIStore';
import { useGeofenceStore, type Geofence } from '../store/useGeofenceStore';
import { useAlertStore } from '../store/useAlertStore';
import { X, User, Activity, MapPin, Battery, PhoneCall, ShieldAlert, Trash2, Check, Radio, Clock, ShieldCheck, CheckCircle } from 'lucide-react';
import { intervalToDuration } from 'date-fns';

const IncidentTimer = ({ startTime }: { startTime: number }) => {
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);
  
  const duration = intervalToDuration({ start: startTime, end: now });
  const formatted = [
    duration.hours ? `${duration.hours}h` : '',
    duration.minutes ? `${duration.minutes}m` : '',
    `${duration.seconds || 0}s`
  ].filter(Boolean).join(' ');
  return <span className="font-mono text-rose-400 font-bold tracking-wider">{formatted || '0s'}</span>;
};

const MAP_CONTAINER_STYLE = {
  width: '100%',
  height: '100%',
  borderRadius: '0.75rem'
};

const DEFAULT_CENTER = { lat: 30.7352, lng: 79.3235 };

const STATUS_COLORS = {
  safe: '#10B981',
  warning: '#F59E0B',
  critical: '#EF4444',
  offline: '#94A3B8'
};

const ZONE_COLORS = {
  warning: { fill: '#F59E0B', stroke: '#D97706' },
  restricted: { fill: '#F97316', stroke: '#C2410C' },
  exclusion: { fill: '#EF4444', stroke: '#B91C1C' }
};

// SVG path for a location pin with a hole
const MARKER_PATH = 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z';

// Needs to be outside component to avoid re-renders
const LIBRARIES: ("drawing" | "geometry" | "places" | "visualization")[] = ['drawing'];

export default function Map() {
  const { isLoaded } = useJsApiLoader({
    id: 'google-map-script',
    googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY || '',
    libraries: LIBRARIES
  });

  const mapRef = useRef<google.maps.Map | null>(null);
  
  const { positions, selectedTourist, selectTourist } = useTouristStore();
  const { rightPanelOpen, setRightPanelOpen, flyToLocation, setFlyToLocation } = useUIStore();
  const { geofences, activeFilters, addGeofence, deleteGeofence } = useGeofenceStore();
  const { alertFeed, updateAlert } = useAlertStore();

  const [selectedZone, setSelectedZone] = useState<string | null>(null);
  const [isDrawingMode, setIsDrawingMode] = useState(false);
  const [drawingPolygon, setDrawingPolygon] = useState<google.maps.Polygon | null>(null);
  
  const [zoneForm, setZoneForm] = useState({ name: '', type: 'warning' as Geofence['type'] });

  const onLoad = useCallback((map: google.maps.Map) => {
    mapRef.current = map;
    map.setOptions({
      styles: [
        { elementType: 'geometry', stylers: [{ color: '#242f3e' }] },
        { elementType: 'labels.text.stroke', stylers: [{ color: '#242f3e' }] },
        { elementType: 'labels.text.fill', stylers: [{ color: '#746855' }] },
        { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#17263c' }] },
        // Add more dark mode styling here if desired
      ],
      disableDefaultUI: true,
      zoomControl: true,
      mapTypeControl: false,
      streetViewControl: false,
    });
  }, []);

  const onUnmount = useCallback(() => {
    mapRef.current = null;
  }, []);

  useEffect(() => {
    if (flyToLocation && mapRef.current) {
      mapRef.current.panTo({ lat: flyToLocation[1], lng: flyToLocation[0] });
      mapRef.current.setZoom(15);
      setFlyToLocation(null);
    }
  }, [flyToLocation, setFlyToLocation]);

  const activeTourist = selectedTourist ? positions[selectedTourist] : null;
  const activeAlert = activeTourist?.status === 'critical' ? alertFeed.find(a => a.touristId === activeTourist.id && a.priority === 'P0' && a.status !== 'closed') : null;
  const activeZone = selectedZone ? geofences.find(g => g.id === selectedZone) : null;

  // Handle polygon drawn
  const onPolygonComplete = (polygon: google.maps.Polygon) => {
    setDrawingPolygon(polygon);
    setIsDrawingMode(false);
    setSelectedZone('new');
    setRightPanelOpen(true);
    selectTourist(null);
  };

  const handleSaveNewZone = () => {
    if (!drawingPolygon) return;
    const path = drawingPolygon.getPath();
    const coords: [number, number][] = [];
    for (let i = 0; i < path.getLength(); i++) {
      const pt = path.getAt(i);
      coords.push([pt.lng(), pt.lat()]);
    }
    
    const newZone: Geofence = {
      id: `zone-${Date.now()}`,
      name: zoneForm.name || 'New Geofence',
      type: zoneForm.type,
      coordinates: coords
    };
    
    addGeofence(newZone);
    drawingPolygon.setMap(null);
    setDrawingPolygon(null);
    setSelectedZone(null);
    setRightPanelOpen(false);
  };

  const handleCancelDraw = () => {
    if (drawingPolygon) {
      drawingPolygon.setMap(null);
      setDrawingPolygon(null);
    }
    setSelectedZone(null);
    setRightPanelOpen(false);
  };

  if (!isLoaded) {
    return <div className="h-[calc(100vh-8rem)] w-full rounded-xl bg-surface-card animate-pulse flex items-center justify-center">
      <p className="text-muted-text">Loading Google Maps...</p>
    </div>;
  }

  return (
    <div className="relative h-[calc(100vh-8rem)] w-full rounded-xl shadow-2xl border border-surface-border/40">
      
      {/* Mapbox -> Google Maps migration complete */}
      <GoogleMap
        mapContainerStyle={MAP_CONTAINER_STYLE}
        center={DEFAULT_CENTER}
        zoom={10}
        onLoad={onLoad}
        onUnmount={onUnmount}
        onClick={() => {
          if (!isDrawingMode) {
            setRightPanelOpen(false);
            selectTourist(null);
            setSelectedZone(null);
          }
        }}
      >
        {/* Render Tourists */}
        {Object.values(positions).map(pos => (
          <MarkerF
            key={pos.id}
            position={{ lat: pos.lat, lng: pos.lng }}
            icon={{
              path: MARKER_PATH,
              fillColor: STATUS_COLORS[pos.status],
              fillOpacity: 1,
              strokeColor: '#FFFFFF',
              strokeWeight: 1,
              scale: 1.5,
              anchor: new google.maps.Point(12, 24)
            }}
            onClick={() => {
              selectTourist(pos.id);
              setSelectedZone(null);
              setRightPanelOpen(true);
            }}
          />
        ))}

        {/* Render Trail for Selected Tourist */}
        {activeTourist && activeTourist.trail.length > 1 && (
          <PolylineF
            path={activeTourist.trail.map(coord => ({ lat: coord[1], lng: coord[0] }))}
            options={{
              strokeColor: '#818CF8', // Indigo 400
              strokeOpacity: 0.8,
              strokeWeight: 3,
            }}
          />
        )}

        {/* Render Geofences */}
        {geofences.filter(g => activeFilters.includes(g.type)).map(zone => (
          <PolygonF
            key={zone.id}
            paths={zone.coordinates.map(c => ({ lat: c[1], lng: c[0] }))}
            options={{
              fillColor: ZONE_COLORS[zone.type].fill,
              fillOpacity: 0.3,
              strokeColor: ZONE_COLORS[zone.type].stroke,
              strokeWeight: 2,
              clickable: true,
              zIndex: 1
            }}
            onClick={() => {
              if (isDrawingMode) return;
              setSelectedZone(zone.id);
              selectTourist(null);
              setRightPanelOpen(true);
            }}
          />
        ))}

        {/* Drawing Manager */}
        {isDrawingMode && (
          <DrawingManagerF
            onPolygonComplete={onPolygonComplete}
            options={{
              drawingControl: false,
              drawingMode: google.maps.drawing.OverlayType.POLYGON,
              polygonOptions: {
                fillColor: '#F59E0B',
                fillOpacity: 0.3,
                strokeWeight: 2,
                clickable: false,
                editable: true,
                zIndex: 2
              }
            }}
          />
        )}
      </GoogleMap>

      {/* Admin Controls Overlay */}
      <div className="absolute top-4 left-4 bg-surface-card/90 backdrop-blur border border-surface-border p-2 rounded-lg z-10 shadow-lg flex items-center space-x-2">
        <button
          onClick={() => {
            setIsDrawingMode(!isDrawingMode);
            if (!isDrawingMode && drawingPolygon) {
              drawingPolygon.setMap(null);
              setDrawingPolygon(null);
            }
          }}
          className={`px-3 py-1.5 rounded-md text-sm font-medium transition ${isDrawingMode ? 'bg-indigo-600 text-white' : 'bg-surface-bg hover:bg-surface-border/50 text-slate-300'}`}
        >
          {isDrawingMode ? 'Cancel Drawing' : 'Draw New Zone'}
        </button>
      </div>
      
      {/* Right Panel Overlay */}
      {rightPanelOpen && (
        <div className="absolute top-4 right-4 w-80 max-h-[calc(100%-2rem)] overflow-y-auto bg-surface-card/95 backdrop-blur-xl border border-surface-border rounded-xl shadow-2xl flex flex-col z-10 transition-transform duration-300">
          
          {/* Tourist Profile / Incident Panel */}
          {activeTourist && !activeAlert && (
            <>
              <div className="flex items-center justify-between p-4 border-b border-surface-border">
                <h3 className="font-outfit font-semibold text-lg flex items-center space-x-2">
                  <User className="h-5 w-5 text-indigo-400" />
                  <span>Tourist Profile</span>
                </h3>
                <button onClick={() => setRightPanelOpen(false)} className="p-1 rounded-md hover:bg-surface-border/50 text-muted-text hover:text-dark-text">
                  <X className="h-5 w-5" />
                </button>
              </div>
              <div className="p-5 space-y-5">
                <div className="space-y-1">
                  <p className="text-xs text-muted-text uppercase font-semibold">ID Number</p>
                  <p className="font-mono font-medium flex items-center space-x-2">
                    <span>{activeTourist.id}</span>
                    <ShieldCheck className="h-4 w-4 text-emerald-400" />
                  </p>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <p className="text-xs text-muted-text uppercase font-semibold flex items-center space-x-1">
                      <Activity className="h-3.5 w-3.5" /><span>Status</span>
                    </p>
                    <p className={`font-semibold capitalize text-${activeTourist.status === 'safe' ? 'emerald' : activeTourist.status === 'warning' ? 'amber' : activeTourist.status === 'critical' ? 'rose' : 'slate'}-400`}>
                      {activeTourist.status}
                    </p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-xs text-muted-text uppercase font-semibold flex items-center space-x-1">
                      <Battery className="h-3.5 w-3.5" /><span>Battery</span>
                    </p>
                    <p className="font-semibold text-emerald-400">84%</p>
                  </div>
                </div>
                <div className="space-y-2">
                  <p className="text-xs text-muted-text uppercase font-semibold flex items-center space-x-1">
                    <MapPin className="h-3.5 w-3.5" /><span>Coordinates</span>
                  </p>
                  <div className="bg-surface-bg p-3 rounded-lg border border-surface-border text-sm font-mono text-slate-300">
                    <p>Lat: {activeTourist.lat.toFixed(6)}</p>
                    <p>Lng: {activeTourist.lng.toFixed(6)}</p>
                  </div>
                </div>
              </div>
              <div className="p-4 border-t border-surface-border bg-surface-bg/50">
                <button className="w-full flex justify-center space-x-2 bg-indigo-600 hover:bg-indigo-700 text-white py-2 rounded-lg font-medium transition">
                  <PhoneCall className="h-4 w-4" /><span>Ping Device</span>
                </button>
              </div>
            </>
          )}

          {/* SOS Incident Card */}
          {activeTourist && activeAlert && (
            <div className="bg-rose-500/5">
              <div className="flex items-center justify-between p-4 border-b border-rose-500/20 bg-rose-500/10">
                <h3 className="font-outfit font-semibold text-lg flex items-center space-x-2 text-rose-400">
                  <ShieldAlert className="h-5 w-5 animate-pulse" />
                  <span>Active Incident</span>
                </h3>
                <button onClick={() => setRightPanelOpen(false)} className="p-1 rounded-md hover:bg-rose-500/20 text-rose-400">
                  <X className="h-5 w-5" />
                </button>
              </div>
              <div className="p-5 space-y-5">
                <div className="flex justify-between items-center bg-rose-500/10 border border-rose-500/20 p-3 rounded-lg">
                  <div className="flex flex-col">
                    <span className="text-xs text-rose-300 uppercase font-semibold flex items-center space-x-1">
                      <Clock className="h-3.5 w-3.5" /><span>Time since SOS</span>
                    </span>
                    <IncidentTimer startTime={activeAlert.timestamp} />
                  </div>
                  <div className="flex flex-col items-end">
                    <span className="text-xs text-rose-300 uppercase font-semibold">Status</span>
                    <span className="font-bold text-rose-400 capitalize">{activeAlert.status}</span>
                  </div>
                </div>
                <div className="space-y-1">
                  <p className="text-xs text-muted-text uppercase font-semibold">Tourist Identity</p>
                  <p className="font-mono font-medium flex items-center space-x-2 text-slate-200">
                    <span>{activeTourist.id}</span>
                    <ShieldCheck className="h-4 w-4 text-emerald-400" />
                  </p>
                </div>
                <div className="space-y-2">
                  <p className="text-xs text-muted-text uppercase font-semibold flex items-center space-x-1">
                    <MapPin className="h-3.5 w-3.5" /><span>Real-time GPS</span>
                  </p>
                  <div className="bg-surface-bg p-3 rounded-lg border border-surface-border text-sm font-mono text-slate-300">
                    <p className="text-rose-300">Lat: {activeTourist.lat.toFixed(6)}</p>
                    <p className="text-rose-300">Lng: {activeTourist.lng.toFixed(6)}</p>
                  </div>
                </div>
                <div className="space-y-2">
                  <p className="text-xs text-muted-text uppercase font-semibold flex items-center space-x-1">
                    <Radio className="h-3.5 w-3.5" /><span>Communication</span>
                  </p>
                  <div className="text-sm space-y-1">
                    <p className="text-slate-300"><span className="text-slate-500">Channel used:</span> Satellite GPS</p>
                    <p className="text-slate-300"><span className="text-slate-500">Attempted:</span> GSM (Failed)</p>
                  </div>
                </div>
              </div>
              <div className="p-4 border-t border-rose-500/20 bg-surface-bg/80 flex flex-col space-y-2">
                {activeAlert.status === 'new' && (
                  <button 
                    onClick={() => updateAlert(activeAlert.id, { status: 'acknowledged' })}
                    className="w-full flex justify-center space-x-2 bg-indigo-600 hover:bg-indigo-700 text-white py-2 rounded-lg font-medium transition"
                  >
                    <CheckCircle className="h-4 w-4" /><span>Acknowledge SOS</span>
                  </button>
                )}
                {activeAlert.status === 'acknowledged' && (
                  <button 
                    onClick={() => updateAlert(activeAlert.id, { status: 'assigned' })}
                    className="w-full flex justify-center space-x-2 bg-emerald-600 hover:bg-emerald-700 text-white py-2 rounded-lg font-medium transition"
                  >
                    <User className="h-4 w-4" /><span>Assign Responder</span>
                  </button>
                )}
                {activeAlert.status === 'assigned' && (
                  <button 
                    onClick={() => updateAlert(activeAlert.id, { status: 'closed' })}
                    className="w-full flex justify-center space-x-2 bg-surface-card hover:bg-surface-border border border-surface-border text-slate-300 py-2 rounded-lg font-medium transition"
                  >
                    <Check className="h-4 w-4" /><span>Resolve Incident (Add Notes)</span>
                  </button>
                )}
              </div>
            </div>
          )}

          {/* New Zone Creation Panel */}
          {selectedZone === 'new' && (
            <>
              <div className="flex items-center justify-between p-4 border-b border-surface-border">
                <h3 className="font-outfit font-semibold text-lg flex items-center space-x-2">
                  <ShieldAlert className="h-5 w-5 text-amber-400" />
                  <span>Create Geofence</span>
                </h3>
              </div>
              <div className="p-5 space-y-4">
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-300">Zone Name</label>
                  <input 
                    type="text" 
                    value={zoneForm.name}
                    onChange={(e) => setZoneForm({...zoneForm, name: e.target.value})}
                    placeholder="e.g. Weather Advisory"
                    className="w-full bg-surface-bg border border-surface-border rounded-lg px-3 py-2 text-sm text-slate-200 outline-none focus:border-indigo-500"
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-slate-300">Zone Type</label>
                  <select 
                    value={zoneForm.type}
                    onChange={(e) => setZoneForm({...zoneForm, type: e.target.value as any})}
                    className="w-full bg-surface-bg border border-surface-border rounded-lg px-3 py-2 text-sm text-slate-200 outline-none focus:border-indigo-500"
                  >
                    <option value="warning">Warning (Amber)</option>
                    <option value="restricted">Restricted (Orange)</option>
                    <option value="exclusion">Exclusion (Red)</option>
                  </select>
                </div>
              </div>
              <div className="p-4 border-t border-surface-border flex space-x-2">
                <button onClick={handleCancelDraw} className="flex-1 py-2 bg-surface-bg hover:bg-surface-border rounded-lg text-sm font-medium transition">
                  Cancel
                </button>
                <button onClick={handleSaveNewZone} className="flex-1 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm font-medium flex justify-center items-center space-x-1 transition">
                  <Check className="h-4 w-4" /><span>Save Zone</span>
                </button>
              </div>
            </>
          )}

          {/* Existing Zone View/Edit Panel */}
          {activeZone && selectedZone !== 'new' && (
            <>
              <div className="flex items-center justify-between p-4 border-b border-surface-border">
                <h3 className="font-outfit font-semibold text-lg flex items-center space-x-2">
                  <ShieldAlert className="h-5 w-5 text-indigo-400" />
                  <span>Zone Details</span>
                </h3>
                <button onClick={() => { setSelectedZone(null); setRightPanelOpen(false); }} className="p-1 rounded-md hover:bg-surface-border/50 text-muted-text">
                  <X className="h-5 w-5" />
                </button>
              </div>
              <div className="p-5 space-y-5">
                <div className="space-y-1">
                  <p className="text-xs text-muted-text uppercase font-semibold">Zone Name</p>
                  <p className="font-medium text-slate-200">{activeZone.name}</p>
                </div>
                <div className="space-y-1">
                  <p className="text-xs text-muted-text uppercase font-semibold">Classification</p>
                  <span className={`inline-block px-2 py-1 rounded text-xs font-semibold capitalize bg-surface-bg border border-surface-border ${
                    activeZone.type === 'warning' ? 'text-amber-400' :
                    activeZone.type === 'restricted' ? 'text-orange-400' : 'text-rose-400'
                  }`}>
                    {activeZone.type}
                  </span>
                </div>
                <div className="space-y-1">
                  <p className="text-xs text-muted-text uppercase font-semibold">Coordinates</p>
                  <p className="text-xs text-slate-400">{activeZone.coordinates.length} vertices plotted</p>
                </div>
              </div>
              <div className="p-4 border-t border-surface-border bg-surface-bg/50 flex space-x-2">
                <button 
                  onClick={() => {
                    deleteGeofence(activeZone.id);
                    setSelectedZone(null);
                    setRightPanelOpen(false);
                  }}
                  className="flex-1 flex justify-center items-center space-x-2 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 py-2 rounded-lg font-medium border border-rose-500/20 transition"
                >
                  <Trash2 className="h-4 w-4" /><span>Delete</span>
                </button>
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
}
