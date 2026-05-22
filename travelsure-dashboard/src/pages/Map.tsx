export default function Map() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-slate-100">Live Operations Map</h1>
        <p className="text-slate-400 mt-1">Real-time geospatial tracking of tourist coordinates, rescue teams, and safe paths.</p>
      </div>
      <div className="glass-panel h-[600px] rounded-xl flex items-center justify-center bg-slate-900/50 relative overflow-hidden">
        <div className="absolute inset-0 bg-slate-950/20 backdrop-blur-[2px]" />
        <div className="relative text-center space-y-4">
          <p className="text-slate-400">Mapbox WebGL component will initialize here.</p>
        </div>
      </div>
    </div>
  );
}
