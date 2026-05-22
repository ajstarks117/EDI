import { useState } from 'react';
import { Link } from 'react-router-dom';
import { 
  BookOpen, 
  Radio, 
  Map, 
  Bell, 
  ShieldAlert, 
  Users, 
  Keyboard, 
  AlertCircle, 
  ArrowRight,
  ExternalLink,
  Check,
  X,
  Info,
  Layers,
  Activity,
  Cpu,
  Tv,
  CornerDownRight
} from 'lucide-react';

export default function Help() {
  const currentVersion = "v1.2.5";
  const lastUpdated = "2026-05-22";

  // RBAC Interactivity State
  const [selectedRole, setSelectedRole] = useState<'operator' | 'dispatcher' | 'admin'>('dispatcher');

  // Keyboard Shortcut Tester State
  const [testResult, setTestResult] = useState<string>('Press a key combination in the input below to test...');
  const [testerInput, setTesterInput] = useState<string>('');

  const handleShortcutTest = (e: React.KeyboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const key = e.key;
    const alt = e.altKey;
    const ctrl = e.ctrlKey;
    const shift = e.shiftKey;

    let shortcutStr = '';
    if (ctrl) shortcutStr += 'Ctrl + ';
    if (alt) shortcutStr += 'Alt + ';
    if (shift) shortcutStr += 'Shift + ';
    shortcutStr += key === ' ' ? 'Space' : key;

    let action = '';
    if (key === 'Enter' || key === ' ') {
      action = '🟢 [ACKNOWLEDGE ALERT] - Acknowledges the active SOS alarm and silences operator audio.';
    } else if (key === 'Escape') {
      action = '🟡 [DISMISS MODAL / RESET] - Exits active dialogs and drawing operations.';
    } else if (alt && (key === 'd' || key === 'D')) {
      action = '🔵 [TOGGLE DEMO MODE] - Injects smart telemetry walkthroughs for presentation acts.';
    } else if (alt && (key === 't' || key === 'T')) {
      action = '🟣 [TOGGLE DARK THEME] - Switches UI color variables instantly.';
    } else {
      action = `⚪ [UNMAPPED KEY] - "${shortcutStr}" is not registered to an operator shortcut.`;
    }

    setTestResult(action);
    setTesterInput('');
  };

  const rbacPermissions = {
    operator: {
      telemetry: true,
      ack: false,
      geofence: false,
      settings: false,
    },
    dispatcher: {
      telemetry: true,
      ack: true,
      geofence: true,
      settings: false,
    },
    admin: {
      telemetry: true,
      ack: true,
      geofence: true,
      settings: true,
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      
      {/* Top Warning Banner: Stale Docs Protection */}
      <div className="bg-amber-500/10 border border-amber-500/20 rounded-xl p-4 flex items-start space-x-3 text-amber-300">
        <Info className="h-5 w-5 shrink-0 mt-0.5" />
        <div className="text-xs space-y-1.5 leading-relaxed">
          <p className="font-semibold text-amber-200">Avoid Stale Documentation Warning</p>
          <p className="text-slate-400">
            This in-app operations manual is updated periodically. For the canonical, latest production deployment guidelines, Vercel SPA fallbacks, and security headers (CSP, HSTS), always check the repository's main readme file.
          </p>
          <a 
            href="https://github.com/ajstarks117/EDI" 
            target="_blank" 
            rel="noopener noreferrer" 
            className="inline-flex items-center space-x-1.5 text-amber-400 hover:text-amber-300 font-bold transition mt-1 focus:outline-none focus:ring-1 focus:ring-amber-400"
          >
            <span>Repository README (Canonical Source)</span>
            <ExternalLink className="h-3 w-3" />
          </a>
        </div>
      </div>

      {/* Page Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center border-b border-surface-border/40 pb-6 gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-100 flex items-center space-x-3">
            <BookOpen className="h-8 w-8 text-indigo-400" />
            <span>Help & Canonical Operations Docs</span>
          </h1>
          <p className="text-slate-400 mt-1">In-app guide summarizing real-time systems, role permissions, and incident troubleshooting workflows.</p>
        </div>
        <div className="text-left md:text-right shrink-0">
          <span className="px-2.5 py-1 text-xs font-bold rounded bg-indigo-500/10 border border-indigo-500/20 text-indigo-400">
            System Version: {currentVersion}
          </span>
          <p className="text-[10px] text-slate-500 mt-1 font-medium">Last Updated: {lastUpdated}</p>
        </div>
      </div>

      {/* Main Grid Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Left Column - Core Architecture & Workflows (Spans 2 columns) */}
        <div className="lg:col-span-2 space-y-8">
          
          {/* Section 1: Realtime Telemetry Architecture */}
          <section className="glass-panel p-6 rounded-xl space-y-4" aria-labelledby="telemetry-title">
            <h2 id="telemetry-title" className="text-xl font-bold text-slate-200 flex items-center space-x-2.5">
              <Radio className="h-5 w-5 text-indigo-400 animate-pulse" />
              <span>1. Real-Time Telemetry & Data Ingestion Flow</span>
            </h2>
            
            <p className="text-sm text-slate-400 leading-relaxed">
              The TravelTrek system uses dynamic, low-latency WebSockets to feed live tourist coordinates and active emergency beacons directly into the Control Operations dashboard.
            </p>

            {/* Interactive Visual Stepper */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-3 bg-surface-bg/40 p-4 rounded-xl border border-surface-border/30 text-xs">
              <div className="space-y-2">
                <div className="flex items-center space-x-2 font-bold text-indigo-400">
                  <Activity className="h-4 w-4 shrink-0" />
                  <span>Act 1: Wearable</span>
                </div>
                <p className="text-[11px] text-slate-400 leading-normal">
                  SOS beacon broadcast periodic satellite/GPS telemetry coordinates.
                </p>
              </div>
              <div className="space-y-2 md:border-l md:border-surface-border/30 md:pl-3">
                <div className="flex items-center space-x-2 font-bold text-emerald-400">
                  <Layers className="h-4 w-4 shrink-0" />
                  <span>Act 2: BLE Mesh</span>
                </div>
                <p className="text-[11px] text-slate-400 leading-normal">
                  If LTE drops, signal hops between local BLE Mesh nodes to reach a gateway.
                </p>
              </div>
              <div className="space-y-2 md:border-l md:border-surface-border/30 md:pl-3">
                <div className="flex items-center space-x-2 font-bold text-amber-400">
                  <Cpu className="h-4 w-4 shrink-0" />
                  <span>Act 3: Ingestion</span>
                </div>
                <p className="text-[11px] text-slate-400 leading-normal">
                  Node gateway captures payloads, instantly streaming frames via WebSockets.
                </p>
              </div>
              <div className="space-y-2 md:border-l md:border-surface-border/30 md:pl-3">
                <div className="flex items-center space-x-2 font-bold text-indigo-400">
                  <Tv className="h-4 w-4 shrink-0" />
                  <span>Act 4: Buffer</span>
                </div>
                <p className="text-[11px] text-slate-400 leading-normal">
                  Zustand buffer debounces map coordinates to ensure 60fps canvas performance.
                </p>
              </div>
            </div>

            <div className="flex justify-between items-center bg-indigo-500/5 border border-indigo-500/10 p-3 rounded-lg text-xs">
              <span className="text-slate-400">Monitor live signal connectivity in real-time.</span>
              <Link to="/dashboard" className="text-indigo-400 hover:text-indigo-300 font-bold flex items-center space-x-1.5 transition">
                <span>Operations Dashboard</span>
                <ArrowRight className="h-3.5 w-3.5" />
              </Link>
            </div>
          </section>

          {/* Section 2: Map Controls & Gestures */}
          <section className="glass-panel p-6 rounded-xl space-y-4" aria-labelledby="map-controls-title">
            <h2 id="map-controls-title" className="text-xl font-bold text-slate-200 flex items-center space-x-2.5">
              <Map className="h-5 w-5 text-emerald-400" />
              <span>2. Interactive Map Gestures & Controls</span>
            </h2>
            <p className="text-sm text-slate-400 leading-relaxed">
              The Live Map canvas leverages the Google Maps JavaScript SDK, customized with extreme high-contrast dark theme presets and hybrid satellite layers.
            </p>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="bg-surface-bg/50 p-4 rounded-lg border border-surface-border/40 space-y-2">
                <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider">Canvas Gestures</h4>
                <ul className="text-xs text-slate-400 space-y-2 list-disc pl-4 leading-relaxed">
                  <li><strong>Panning View:</strong> Hold left-click and drag anywhere across the topographical terrain.</li>
                  <li><strong>Zoom Adjustments:</strong> Pinch trackpad, scroll mouse wheel, or use the floating control overlays.</li>
                  <li><strong>Focus Tracking:</strong> Clicking any active incident card automatically locks the viewport coordinate center.</li>
                </ul>
              </div>

              <div className="bg-surface-bg/50 p-4 rounded-lg border border-surface-border/40 space-y-2">
                <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider">Layer Configurations</h4>
                <ul className="text-xs text-slate-400 space-y-2 list-disc pl-4 leading-relaxed">
                  <li><strong>Theme Contrast Toggle:</strong> Switch styles via the theme button at the top header.</li>
                  <li><strong>Hybrid Imagery:</strong> Toggle dynamic satellite and contour path layers inside map widgets.</li>
                  <li><strong>Telemetry Update Indicator:</strong> Flashing green markers declare active BLE heartbeats.</li>
                </ul>
              </div>
            </div>

            <div className="flex justify-between items-center bg-emerald-500/5 border border-emerald-500/10 p-3 rounded-lg text-xs">
              <span className="text-slate-400">Access full vector maps, topological profiles, and satellite views.</span>
              <Link to="/map" className="text-emerald-400 hover:text-emerald-300 font-bold flex items-center space-x-1.5 transition">
                <span>Open Live Map</span>
                <ArrowRight className="h-3.5 w-3.5" />
              </Link>
            </div>
          </section>

          {/* Section 3: Alert Dispatch & Resolution Workflow */}
          <section className="glass-panel p-6 rounded-xl space-y-4" aria-labelledby="alert-workflow-title">
            <h2 id="alert-workflow-title" className="text-xl font-bold text-slate-200 flex items-center space-x-2.5">
              <Bell className="h-5 w-5 text-rose-400" />
              <span>3. Emergency SOS Dispatch Life Cycle</span>
            </h2>
            <p className="text-sm text-slate-400">
              When an SOS panic event initiates, operators transition active incident cards across four key timeline acts:
            </p>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-3 text-center">
              <div className="bg-rose-500/10 border border-rose-500/20 p-3.5 rounded-lg">
                <span className="text-xs font-black text-rose-400 block mb-1">Act 1: NEW</span>
                <p className="text-[10px] text-slate-400 leading-relaxed">P0 Distress received. Alarm buzzer activates. Sidebar overlays force focus.</p>
              </div>
              <div className="bg-amber-500/10 border border-amber-500/20 p-3.5 rounded-lg">
                <span className="text-xs font-black text-amber-400 block mb-1">Act 2: ACKED</span>
                <p className="text-[10px] text-slate-400 leading-relaxed">Operator acknowledges active event. Buzzer silences; coordinates trace.</p>
              </div>
              <div className="bg-indigo-500/10 border border-indigo-500/20 p-3.5 rounded-lg">
                <span className="text-xs font-black text-indigo-400 block mb-1">Act 3: ASSIGNED</span>
                <p className="text-[10px] text-slate-400 leading-relaxed">Dispatcher coordinates local search responders. Rescue logs populate.</p>
              </div>
              <div className="bg-emerald-500/10 border border-emerald-500/20 p-3.5 rounded-lg">
                <span className="text-xs font-black text-emerald-400 block mb-1">Act 4: CLOSED</span>
                <p className="text-[10px] text-slate-400 leading-relaxed">Tourist safe. Dispatch logs locked and hashes written to smart contract.</p>
              </div>
            </div>

            <div className="flex justify-between items-center bg-rose-500/5 border border-rose-500/10 p-3 rounded-lg text-xs">
              <span className="text-slate-400">Respond to active triggers, monitor audio alarms, and update dispatches.</span>
              <Link to="/alerts" className="text-rose-400 hover:text-rose-300 font-bold flex items-center space-x-1.5 transition">
                <span>View Emergency Console</span>
                <ArrowRight className="h-3.5 w-3.5" />
              </Link>
            </div>
          </section>

          {/* Section 4: Geo-fence CRUD Procedures */}
          <section className="glass-panel p-6 rounded-xl space-y-4" aria-labelledby="geofence-title">
            <h2 id="geofence-title" className="text-xl font-bold text-slate-200 flex items-center space-x-2.5">
              <ShieldAlert className="h-5 w-5 text-amber-400" />
              <span>4. Dynamic Geo-fence Draw & CRUD Guidelines</span>
            </h2>
            <p className="text-sm text-slate-400 leading-relaxed">
              Geo-fences protect off-grid tourists by raising automatic warnings whenever coordinate traces violate boundary limits.
            </p>

            <div className="bg-surface-bg/50 p-5 rounded-lg border border-surface-border/40 text-xs space-y-3 leading-relaxed">
              <div className="flex items-start space-x-2.5">
                <span className="h-5 w-5 rounded bg-indigo-500/10 border border-indigo-500/30 text-indigo-400 flex items-center justify-center font-bold text-[10px] shrink-0">1</span>
                <div>
                  <p className="font-bold text-slate-200">Draw Exclusion Boundary</p>
                  <p className="text-slate-400 text-[11px] mt-0.5">Click "Draw New Zone" in the Geofence manager, then left-click vertices sequentially on the canvas to outline the warning bounds. Double-click to complete.</p>
                </div>
              </div>
              <div className="flex items-start space-x-2.5 border-t border-surface-border/30 pt-3">
                <span className="h-5 w-5 rounded bg-indigo-500/10 border border-indigo-500/30 text-indigo-400 flex items-center justify-center font-bold text-[10px] shrink-0">2</span>
                <div>
                  <p className="font-bold text-slate-200">Assign Threat Profile</p>
                  <p className="text-slate-400 text-[11px] mt-0.5">Categorize zones as <span className="text-amber-400 font-semibold">Warning (Alert Trigger)</span>, <span className="text-orange-400 font-semibold">Restricted (Continuous tracking)</span>, or <span className="text-rose-400 font-semibold">Exclusion (No-go Zone)</span>.</p>
                </div>
              </div>
              <div className="flex items-start space-x-2.5 border-t border-surface-border/30 pt-3">
                <span className="h-5 w-5 rounded bg-indigo-500/10 border border-indigo-500/30 text-indigo-400 flex items-center justify-center font-bold text-[10px] shrink-0">3</span>
                <div>
                  <p className="font-bold text-slate-200">Save and Broadcast</p>
                  <p className="text-slate-400 text-[11px] mt-0.5">Save changes. Bound matrices sync dynamically to device memories. Active alerts trigger automatically on telemetry intersection.</p>
                </div>
              </div>
            </div>

            <div className="flex justify-between items-center bg-amber-500/5 border border-amber-500/10 p-3 rounded-lg text-xs">
              <span className="text-slate-400">Configure safety boundaries and assign hazard profiles.</span>
              <Link to="/geofences" className="text-amber-400 hover:text-amber-300 font-bold flex items-center space-x-1.5 transition">
                <span>Manage Geo-fences</span>
                <ArrowRight className="h-3.5 w-3.5" />
              </Link>
            </div>
          </section>

        </div>

        {/* Right Column - Role Matrix, Troubleshooting, Keyboard Tester */}
        <div className="space-y-8">
          
          {/* Interactive Role Authorization (RBAC Matrix) */}
          <section className="glass-panel p-6 rounded-xl space-y-4" aria-labelledby="rbac-title">
            <h2 id="rbac-title" className="text-lg font-bold text-slate-200 flex items-center space-x-2">
              <Users className="h-5 w-5 text-indigo-400" />
              <span>Interactive Role Matrix</span>
            </h2>
            <p className="text-xs text-slate-400 leading-relaxed">
              Verify operator capabilities based on Role-Based Access Control (RBAC). Select a role below to check dynamic permissions:
            </p>

            {/* Role Tab Toggles */}
            <div className="grid grid-cols-3 gap-1 bg-surface-bg p-1 rounded-lg border border-surface-border">
              {(['operator', 'dispatcher', 'admin'] as const).map((role) => (
                <button
                  key={role}
                  onClick={() => setSelectedRole(role)}
                  className={`py-1.5 text-[10px] font-bold uppercase tracking-wider rounded transition-all focus:outline-none focus:ring-1 focus:ring-indigo-500 ${
                    selectedRole === role 
                      ? 'bg-indigo-600 text-white shadow-md' 
                      : 'text-slate-400 hover:text-slate-200 hover:bg-surface-card/40'
                  }`}
                >
                  {role}
                </button>
              ))}
            </div>

            {/* Permission Checklist */}
            <div className="space-y-2 text-xs pt-1">
              <div className="flex justify-between items-center p-2.5 rounded bg-surface-bg border border-surface-border/40">
                <span className="text-slate-300">Read-Only Live Telemetry</span>
                {rbacPermissions[selectedRole].telemetry ? (
                  <Check className="h-4.5 w-4.5 text-emerald-400 shrink-0" />
                ) : (
                  <X className="h-4.5 w-4.5 text-rose-400 shrink-0" />
                )}
              </div>
              <div className="flex justify-between items-center p-2.5 rounded bg-surface-bg border border-surface-border/40">
                <span className="text-slate-300">Acknowledge & Closed Alert Status</span>
                {rbacPermissions[selectedRole].ack ? (
                  <Check className="h-4.5 w-4.5 text-emerald-400 shrink-0" />
                ) : (
                  <X className="h-4.5 w-4.5 text-rose-400 shrink-0" />
                )}
              </div>
              <div className="flex justify-between items-center p-2.5 rounded bg-surface-bg border border-surface-border/40">
                <span className="text-slate-300">Draw & Modify Exclusion Zones</span>
                {rbacPermissions[selectedRole].geofence ? (
                  <Check className="h-4.5 w-4.5 text-emerald-400 shrink-0" />
                ) : (
                  <X className="h-4.5 w-4.5 text-rose-400 shrink-0" />
                )}
              </div>
              <div className="flex justify-between items-center p-2.5 rounded bg-surface-bg border border-surface-border/40">
                <span className="text-slate-300">Access Global Settings & Keys</span>
                {rbacPermissions[selectedRole].settings ? (
                  <Check className="h-4.5 w-4.5 text-emerald-400 shrink-0" />
                ) : (
                  <X className="h-4.5 w-4.5 text-rose-400 shrink-0" />
                )}
              </div>
            </div>

            <div className="pt-2 border-t border-surface-border/30 text-center">
              <Link to="/settings" className="text-[11px] text-indigo-400 hover:text-indigo-300 font-semibold inline-flex items-center space-x-1.5">
                <span>Configure Profile Settings</span>
                <ArrowRight className="h-3 w-3" />
              </Link>
            </div>
          </section>

          {/* Self-Healing & Troubleshooting Diagnostic Panel */}
          <section className="glass-panel p-6 rounded-xl space-y-4 border border-rose-500/20 bg-rose-500/5" aria-labelledby="troubleshooting-title">
            <h2 id="troubleshooting-title" className="text-base font-bold text-rose-300 flex items-center space-x-2">
              <AlertCircle className="h-5 w-5 text-rose-400 shrink-0 animate-bounce" />
              <span>Diagnostic & Self-Healing Guide</span>
            </h2>
            
            <div className="text-xs space-y-3.5 leading-relaxed">
              <div className="space-y-1 bg-surface-bg/30 p-2.5 rounded border border-rose-500/10">
                <h4 className="font-bold text-slate-200 flex items-center space-x-1">
                  <span>🔌 Issue: Socket Down / Disconnected</span>
                </h4>
                <p className="text-slate-400 text-[11px] mt-1">
                  The dashboard status indicator switches to "Disconnected". 
                  <strong className="text-rose-300"> Self-Healing:</strong> The client triggers automatic reconnection algorithms with exponential backoffs (delay increases exponentially to avoid server DDoS).
                </p>
                <Link to="/settings" className="text-[10px] text-rose-400 hover:text-rose-300 font-bold inline-flex items-center space-x-1 mt-1.5">
                  <span>Manage Server Port ➔</span>
                </Link>
              </div>

              <div className="space-y-1 bg-surface-bg/30 p-2.5 rounded border border-rose-500/10">
                <h4 className="font-bold text-slate-200 flex items-center space-x-1">
                  <span>🗺️ Issue: Google Maps Invalid Token</span>
                </h4>
                <p className="text-slate-400 text-[11px] mt-1">
                  Topographical grid fails to render or console displays API authorization warnings.
                  <strong className="text-rose-300"> Resolution:</strong> Verify that VITE_GOOGLE_MAPS_API_KEY inside your .env template is configured with standard JS Map permissions.
                </p>
                <Link to="/settings" className="text-[10px] text-rose-400 hover:text-rose-300 font-bold inline-flex items-center space-x-1 mt-1.5">
                  <span>Check Env API Key ➔</span>
                </Link>
              </div>
            </div>
          </section>

          {/* Keyboard Shortcuts & Interactive Key Tester */}
          <section className="glass-panel p-6 rounded-xl space-y-4" aria-labelledby="shortcuts-title">
            <h2 id="shortcuts-title" className="text-base font-bold text-slate-200 flex items-center space-x-2">
              <Keyboard className="h-5 w-5 text-indigo-400" />
              <span>Keyboard Nav & Shortcuts</span>
            </h2>

            <div className="text-xs space-y-2.5">
              <div className="flex justify-between items-center border-b border-surface-border/20 pb-2">
                <span className="text-slate-400">Acknowledge Alert</span>
                <kbd className="px-2 py-0.5 bg-surface-bg border border-surface-border/60 rounded text-[10px] font-mono text-slate-200">Space / Enter</kbd>
              </div>
              <div className="flex justify-between items-center border-b border-surface-border/20 pb-2">
                <span className="text-slate-400">Dismiss Modal / Reset</span>
                <kbd className="px-2 py-0.5 bg-surface-bg border border-surface-border/60 rounded text-[10px] font-mono text-slate-200">Escape</kbd>
              </div>
              <div className="flex justify-between items-center border-b border-surface-border/20 pb-2">
                <span className="text-slate-400">Toggle simulated evaluation</span>
                <kbd className="px-2 py-0.5 bg-surface-bg border border-surface-border/60 rounded text-[10px] font-mono text-slate-200">Alt + D</kbd>
              </div>
              <div className="flex justify-between items-center border-b border-surface-border/20 pb-2">
                <span className="text-slate-400">Toggle system theme dark/light</span>
                <kbd className="px-2 py-0.5 bg-surface-bg border border-surface-border/60 rounded text-[10px] font-mono text-slate-200">Alt + T</kbd>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-slate-400">Skip to Main Content focus</span>
                <kbd className="px-2 py-0.5 bg-surface-bg border border-surface-border/60 rounded text-[10px] font-mono text-slate-200">Tab (Initial)</kbd>
              </div>
            </div>

            {/* Dynamic Keyboard Sandbox */}
            <div className="bg-surface-bg p-4 rounded-lg border border-surface-border space-y-3">
              <h4 className="text-xs font-bold text-slate-300 flex items-center space-x-1.5">
                <CornerDownRight className="h-3.5 w-3.5 text-indigo-400" />
                <span>Interactive Shortcut Tester</span>
              </h4>
              <p className="text-[10px] text-slate-400 leading-relaxed">
                Click inside the field below and trigger an active combination (e.g. Escape, Enter, Alt+D, Alt+T) to test binding callbacks.
              </p>
              <input
                type="text"
                value={testerInput}
                onChange={(e) => setTesterInput(e.target.value)}
                onKeyDown={handleShortcutTest}
                placeholder="Click here and press keys..."
                className="w-full text-xs bg-surface-card border border-surface-border rounded p-2 text-slate-200 focus:outline-none focus:border-indigo-500 font-mono transition"
                aria-label="Keyboard shortcut tester input field"
              />
              <div className="p-2.5 rounded bg-surface-card/60 border border-surface-border/30 text-[10px] text-indigo-300 font-mono leading-normal break-words">
                {testResult}
              </div>
            </div>
          </section>

        </div>

      </div>
    </div>
  );
}
