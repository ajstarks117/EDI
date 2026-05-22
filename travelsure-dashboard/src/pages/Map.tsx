import { useEffect, useRef } from 'react';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { useTouristStore } from '../store/useTouristStore';
import { useUIStore } from '../store/useUIStore';
import { X, User, Activity, MapPin, Battery, PhoneCall } from 'lucide-react';

const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN || 'pk.eyJ1IjoibW9jay10b2tlbiIsImEiOiJtb2NrLWtleSJ9.mock';

// We'll generate simple SVG ring images as data URIs for mapbox markers.
const getMarkerSvg = (color: string) => `data:image/svg+xml;utf8,${encodeURIComponent(`
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="${color}" fill-opacity="0.2" stroke="${color}" stroke-width="2"/>
  <circle cx="12" cy="12" r="5" fill="${color}"/>
</svg>
`)}`;

const STATUS_COLORS = {
  safe: '#10B981',     // Emerald
  warning: '#F59E0B',  // Amber
  critical: '#EF4444', // Red
  offline: '#94A3B8'   // Slate
};

export default function Map() {
  const mapContainer = useRef<HTMLDivElement>(null);
  const map = useRef<mapboxgl.Map | null>(null);
  
  const { positions, selectedTourist, selectTourist } = useTouristStore();
  const { rightPanelOpen, setRightPanelOpen } = useUIStore();
  
  // Ref to hold current positions so we can easily update the source
  const positionsRef = useRef(positions);
  useEffect(() => {
    positionsRef.current = positions;
  }, [positions]);

  useEffect(() => {
    if (map.current || !mapContainer.current) return;

    mapboxgl.accessToken = MAPBOX_TOKEN;
    
    map.current = new mapboxgl.Map({
      container: mapContainer.current,
      style: 'mapbox://styles/mapbox/dark-v11', // Dark style matching operations theme
      center: [79.3235, 30.7352], // Default roughly to Uttarakhand/Himalayas area
      zoom: 10
    });

    // Add Controls
    map.current.addControl(new mapboxgl.NavigationControl(), 'top-right');
    map.current.addControl(
      new mapboxgl.GeolocateControl({
        positionOptions: { enableHighAccuracy: true },
        trackUserLocation: false, // off by default
        showUserHeading: true
      }),
      'top-right'
    );

    map.current.on('load', () => {
      const m = map.current!;

      // Load SVGs as map images
      Object.entries(STATUS_COLORS).forEach(([status, color]) => {
        const img = new Image();
        img.src = getMarkerSvg(color);
        img.onload = () => {
          if (!m.hasImage(`marker-${status}`)) {
            m.addImage(`marker-${status}`, img);
          }
        };
      });

      // Add GeoJSON Source
      m.addSource('tourists', {
        type: 'geojson',
        data: { type: 'FeatureCollection', features: [] }
      });

      // Add Symbol Layer for Markers
      m.addLayer({
        id: 'tourists-layer',
        type: 'symbol',
        source: 'tourists',
        layout: {
          'icon-image': ['concat', 'marker-', ['get', 'status']],
          'icon-size': 1,
          'icon-allow-overlap': true
        }
      });

      // Click handler
      m.on('click', 'tourists-layer', (e) => {
        if (e.features && e.features.length > 0) {
          const id = e.features[0].properties?.id;
          if (id) {
            selectTourist(id);
            setRightPanelOpen(true);
          }
        }
      });

      // Pointer cursor
      m.on('mouseenter', 'tourists-layer', () => { m.getCanvas().style.cursor = 'pointer'; });
      m.on('mouseleave', 'tourists-layer', () => { m.getCanvas().style.cursor = ''; });

      // Initial Data sync
      updateGeoJsonSource();
    });

    return () => {
      map.current?.remove();
      map.current = null;
    };
  }, [selectTourist, setRightPanelOpen]);

  // Sync positions from store to map source
  const updateGeoJsonSource = () => {
    if (!map.current || !map.current.getSource('tourists')) return;
    
    const features: GeoJSON.Feature[] = Object.values(positionsRef.current).map(pos => ({
      type: 'Feature',
      properties: {
        id: pos.id,
        status: pos.status,
        lastUpdated: pos.lastUpdated
      },
      geometry: {
        type: 'Point',
        coordinates: [pos.lng, pos.lat]
      }
    }));

    const source = map.current.getSource('tourists') as mapboxgl.GeoJSONSource;
    source.setData({
      type: 'FeatureCollection',
      features
    });
  };

  // Run the update whenever positions change
  useEffect(() => {
    updateGeoJsonSource();
  }, [positions]);

  const activeTourist = selectedTourist ? positions[selectedTourist] : null;

  return (
    <div className="relative h-[calc(100vh-8rem)] w-full rounded-xl overflow-hidden shadow-2xl border border-surface-border/40">
      <div ref={mapContainer} className="absolute inset-0" />
      
      {/* Right Panel Overlay */}
      {rightPanelOpen && activeTourist && (
        <div className="absolute top-4 right-14 w-80 bg-surface-card/95 backdrop-blur-xl border border-surface-border rounded-xl shadow-2xl flex flex-col z-10 transition-transform duration-300">
          <div className="flex items-center justify-between p-4 border-b border-surface-border">
            <h3 className="font-outfit font-semibold text-lg flex items-center space-x-2">
              <User className="h-5 w-5 text-indigo-400" />
              <span>Tourist Profile</span>
            </h3>
            <button 
              onClick={() => setRightPanelOpen(false)}
              className="p-1 rounded-md hover:bg-surface-border/50 text-muted-text hover:text-dark-text transition"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
          
          <div className="p-5 space-y-5">
            <div className="space-y-1">
              <p className="text-xs text-muted-text uppercase font-semibold tracking-wider">ID Number</p>
              <p className="font-mono font-medium">{activeTourist.id}</p>
            </div>
            
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1">
                <p className="text-xs text-muted-text uppercase font-semibold tracking-wider flex items-center space-x-1">
                  <Activity className="h-3.5 w-3.5" />
                  <span>Status</span>
                </p>
                <p className={`font-semibold capitalize
                  ${activeTourist.status === 'safe' ? 'text-emerald-400' : ''}
                  ${activeTourist.status === 'warning' ? 'text-amber-400' : ''}
                  ${activeTourist.status === 'critical' ? 'text-rose-400' : ''}
                  ${activeTourist.status === 'offline' ? 'text-slate-400' : ''}
                `}>
                  {activeTourist.status}
                </p>
              </div>
              <div className="space-y-1">
                <p className="text-xs text-muted-text uppercase font-semibold tracking-wider flex items-center space-x-1">
                  <Battery className="h-3.5 w-3.5" />
                  <span>Battery</span>
                </p>
                <p className="font-semibold text-emerald-400">84%</p>
              </div>
            </div>

            <div className="space-y-2">
              <p className="text-xs text-muted-text uppercase font-semibold tracking-wider flex items-center space-x-1">
                <MapPin className="h-3.5 w-3.5" />
                <span>Last Coordinates</span>
              </p>
              <div className="bg-surface-bg p-3 rounded-lg border border-surface-border text-sm font-mono text-slate-300">
                <p>Lat: {activeTourist.lat.toFixed(6)}</p>
                <p>Lng: {activeTourist.lng.toFixed(6)}</p>
              </div>
              <p className="text-[10px] text-muted-text text-right mt-1">
                Updated: {new Date(activeTourist.lastUpdated).toLocaleTimeString()}
              </p>
            </div>
          </div>
          
          <div className="p-4 border-t border-surface-border bg-surface-bg/50 rounded-b-xl">
            <button className="w-full flex items-center justify-center space-x-2 bg-indigo-600 hover:bg-indigo-700 text-white py-2 rounded-lg font-medium transition">
              <PhoneCall className="h-4 w-4" />
              <span>Ping Device</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
