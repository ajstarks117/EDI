import { useState, useEffect } from 'react';
import { useSettingsStore } from '../store/useSettingsStore';
import { Save, RotateCcw, Volume2, Map as MapIcon, Server, User, Globe, Bell } from 'lucide-react';
import { useUIStore } from '../store/useUIStore';

export default function Settings() {
  const settings = useSettingsStore();
  const { addToast } = useUIStore();
  
  // Local state for the form so we don't spam the store/localStorage on every keystroke
  const [formData, setFormData] = useState({
    region: settings.region,
    mapDefaultCenterLng: settings.mapDefaultCenter[0].toString(),
    mapDefaultCenterLat: settings.mapDefaultCenter[1].toString(),
    mapDefaultZoom: settings.mapDefaultZoom.toString(),
    soundVolume: (settings.soundVolume * 100).toString(),
    notificationsEnabled: settings.notificationsEnabled,
    apiBaseUrl: settings.apiBaseUrl,
    operatorName: settings.operatorProfile.name,
    operatorRole: settings.operatorProfile.role,
    devModeEnabled: settings.devModeEnabled,
  });

  // Keep local state in sync if store changes externally
  useEffect(() => {
    setFormData({
      region: settings.region,
      mapDefaultCenterLng: settings.mapDefaultCenter[0].toString(),
      mapDefaultCenterLat: settings.mapDefaultCenter[1].toString(),
      mapDefaultZoom: settings.mapDefaultZoom.toString(),
      soundVolume: (settings.soundVolume * 100).toString(),
      notificationsEnabled: settings.notificationsEnabled,
      apiBaseUrl: settings.apiBaseUrl,
      operatorName: settings.operatorProfile.name,
      operatorRole: settings.operatorProfile.role,
      devModeEnabled: settings.devModeEnabled,
    });
  }, [settings]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target;
    if (type === 'checkbox') {
      const checked = (e.target as HTMLInputElement).checked;
      setFormData(prev => ({ ...prev, [name]: checked }));
    } else {
      setFormData(prev => ({ ...prev, [name]: value }));
    }
  };

  const handleSave = () => {
    // Parse numeric values
    const lng = parseFloat(formData.mapDefaultCenterLng) || 0;
    const lat = parseFloat(formData.mapDefaultCenterLat) || 0;
    const zoom = parseInt(formData.mapDefaultZoom, 10) || 12;
    const volume = parseInt(formData.soundVolume, 10) / 100;

    settings.setRegion(formData.region);
    settings.setMapDefaults([lng, lat], zoom);
    settings.setSoundVolume(volume);
    settings.setNotificationsEnabled(formData.notificationsEnabled);
    settings.setApiBaseUrl(formData.apiBaseUrl);
    settings.setOperatorProfile({
      name: formData.operatorName,
      role: formData.operatorRole,
    });
    settings.setDevModeEnabled(formData.devModeEnabled);

    addToast({ message: 'Settings saved successfully. Environment updated.', type: 'success' });
  };

  const handleReset = () => {
    settings.resetSettings();
    addToast({ message: 'Settings reset to defaults.', type: 'info' });
  };

  const testVolume = () => {
    try {
      const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = audioCtx.createOscillator();
      const gainNode = audioCtx.createGain();
      
      oscillator.type = 'sine';
      oscillator.frequency.setValueAtTime(440, audioCtx.currentTime); 
      
      const volume = parseInt(formData.soundVolume, 10) / 100;
      gainNode.gain.setValueAtTime(volume, audioCtx.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.3);
      
      oscillator.connect(gainNode);
      gainNode.connect(audioCtx.destination);
      
      oscillator.start();
      oscillator.stop(audioCtx.currentTime + 0.3);
    } catch (e) {
      console.warn('Test sound blocked:', e);
    }
  };

  return (
    <div className="max-w-4xl mx-auto pb-10">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold font-outfit text-dark-text">System Settings</h1>
          <p className="text-muted-text text-sm">Configure environment, preferences, and operational defaults.</p>
        </div>
        <div className="flex items-center space-x-3">
          <button 
            onClick={handleReset}
            className="flex items-center space-x-2 px-4 py-2 border border-surface-border text-slate-400 hover:text-slate-200 hover:bg-surface-card rounded-lg transition focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <RotateCcw className="h-4 w-4" />
            <span className="text-sm font-medium">Reset</span>
          </button>
          <button 
            onClick={handleSave}
            className="flex items-center space-x-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 focus:ring-offset-surface"
          >
            <Save className="h-4 w-4" />
            <span className="text-sm font-medium">Save Changes</span>
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Operator Profile */}
        <section className="bg-surface-card border border-surface-border rounded-xl p-6">
          <div className="flex items-center space-x-2 mb-4">
            <User className="h-5 w-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-slate-200">Operator Profile</h2>
          </div>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1">Operator Name</label>
              <input 
                type="text" 
                name="operatorName"
                value={formData.operatorName}
                onChange={handleChange}
                className="w-full bg-surface-bg border border-surface-border rounded-md px-3 py-2 text-slate-200 focus:outline-none focus:border-indigo-500 transition"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1">Operational Role</label>
              <select 
                name="operatorRole"
                value={formData.operatorRole}
                onChange={handleChange}
                className="w-full bg-surface-bg border border-surface-border rounded-md px-3 py-2 text-slate-200 focus:outline-none focus:border-indigo-500 transition"
              >
                <option value="admin">Admin</option>
                <option value="dispatcher">Dispatcher</option>
                <option value="analyst">Analyst</option>
                <option value="viewer">Viewer</option>
              </select>
            </div>
          </div>
        </section>

        {/* Environment & Region */}
        <section className="bg-surface-card border border-surface-border rounded-xl p-6">
          <div className="flex items-center space-x-2 mb-4">
            <Globe className="h-5 w-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-slate-200">Environment & Region</h2>
          </div>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 bg-surface-bg border border-surface-border rounded-lg mb-4">
              <div>
                <p className="text-sm font-medium text-slate-200">Developer Mode</p>
                <p className="text-xs text-slate-400">Show FPS & Memory performance overlay</p>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input 
                  type="checkbox" 
                  name="devModeEnabled"
                  checked={formData.devModeEnabled}
                  onChange={handleChange}
                  className="sr-only peer" 
                />
                <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-indigo-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600"></div>
              </label>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1">Region Subscription</label>
              <select 
                name="region"
                value={formData.region}
                onChange={handleChange}
                className="w-full bg-surface-bg border border-surface-border rounded-md px-3 py-2 text-slate-200 focus:outline-none focus:border-indigo-500 transition"
              >
                <option value="global">Global (All Regions)</option>
                <option value="europe">Europe</option>
                <option value="asia">Asia Pacific</option>
                <option value="americas">Americas</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1">API Base URL</label>
              <div className="flex">
                <span className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-surface-border bg-surface-bg text-slate-500 sm:text-sm">
                  <Server className="h-4 w-4" />
                </span>
                <input 
                  type="text" 
                  name="apiBaseUrl"
                  value={formData.apiBaseUrl}
                  onChange={handleChange}
                  className="flex-1 min-w-0 block w-full px-3 py-2 rounded-none rounded-r-md bg-surface-bg border border-surface-border text-slate-200 focus:outline-none focus:border-indigo-500 transition"
                />
              </div>
              <p className="text-xs text-slate-500 mt-1">Changing this reconnects the live socket feed.</p>
            </div>
          </div>
        </section>

        {/* Map Defaults */}
        <section className="bg-surface-card border border-surface-border rounded-xl p-6">
          <div className="flex items-center space-x-2 mb-4">
            <MapIcon className="h-5 w-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-slate-200">Map Defaults</h2>
          </div>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1">Center Longitude</label>
                <input 
                  type="number" 
                  step="0.00001"
                  name="mapDefaultCenterLng"
                  value={formData.mapDefaultCenterLng}
                  onChange={handleChange}
                  className="w-full bg-surface-bg border border-surface-border rounded-md px-3 py-2 text-slate-200 focus:outline-none focus:border-indigo-500 transition"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1">Center Latitude</label>
                <input 
                  type="number" 
                  step="0.00001"
                  name="mapDefaultCenterLat"
                  value={formData.mapDefaultCenterLat}
                  onChange={handleChange}
                  className="w-full bg-surface-bg border border-surface-border rounded-md px-3 py-2 text-slate-200 focus:outline-none focus:border-indigo-500 transition"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-1">Default Zoom Level ({formData.mapDefaultZoom})</label>
              <input 
                type="range" 
                min="1" 
                max="20" 
                name="mapDefaultZoom"
                value={formData.mapDefaultZoom}
                onChange={handleChange}
                className="w-full accent-indigo-500"
              />
            </div>
          </div>
        </section>

        {/* Audio & Notifications */}
        <section className="bg-surface-card border border-surface-border rounded-xl p-6">
          <div className="flex items-center space-x-2 mb-4">
            <Bell className="h-5 w-5 text-indigo-400" />
            <h2 className="text-lg font-semibold text-slate-200">Alerts & Audio</h2>
          </div>
          <div className="space-y-6">
            <div>
              <div className="flex items-center justify-between mb-1">
                <label className="block text-sm font-medium text-slate-400">Master Volume ({formData.soundVolume}%)</label>
                <button onClick={testVolume} aria-label="Test Volume" className="text-xs text-indigo-400 hover:text-indigo-300 flex items-center p-1 rounded focus:outline-none focus:ring-2 focus:ring-indigo-500">
                  <Volume2 className="h-3 w-3 mr-1" /> Test
                </button>
              </div>
              <input 
                type="range" 
                min="0" 
                max="100" 
                name="soundVolume"
                value={formData.soundVolume}
                onChange={handleChange}
                className="w-full accent-indigo-500"
              />
            </div>
            
            <div className="flex items-center justify-between p-3 bg-surface-bg border border-surface-border rounded-lg">
              <div>
                <p className="text-sm font-medium text-slate-200">Desktop Notifications</p>
                <p className="text-xs text-slate-400">Show OS popups for P0/P1 alerts</p>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input 
                  type="checkbox" 
                  name="notificationsEnabled"
                  checked={formData.notificationsEnabled}
                  onChange={handleChange}
                  className="sr-only peer" 
                />
                <div className="w-11 h-6 bg-slate-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-indigo-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600"></div>
              </label>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
