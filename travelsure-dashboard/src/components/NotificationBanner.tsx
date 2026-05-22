import { BellRing, X } from 'lucide-react';
import { useUIStore } from '../store/useUIStore';

export default function NotificationBanner() {
  const { notificationPermission, bannerDismissed, setNotificationPermission, dismissBanner } = useUIStore();

  const isSupported = typeof window !== 'undefined' && 'Notification' in window;
  
  if (!isSupported) return null;
  // If we already asked and it was denied or granted, or if the user explicitly dismissed it, hide it.
  if (notificationPermission !== 'default' || bannerDismissed) return null;

  const requestPermission = async () => {
    try {
      const permission = await Notification.requestPermission();
      setNotificationPermission(permission);
      if (permission !== 'default') {
        dismissBanner();
      }
    } catch (error) {
      console.error('Error requesting notification permission:', error);
    }
  };

  return (
    <div className="bg-indigo-600 px-4 py-3 text-white flex items-center justify-between shadow-md relative z-50">
      <div className="flex items-center space-x-3">
        <div className="bg-white/20 p-2 rounded-lg">
          <BellRing className="h-5 w-5 text-white" />
        </div>
        <div>
          <p className="text-sm font-semibold">Enable Critical Alerts</p>
          <p className="text-xs text-indigo-100">
            Allow notifications to receive instant audio and visual alerts for P0 SOS emergencies even when this tab is closed or unfocused.
          </p>
        </div>
      </div>
      <div className="flex items-center space-x-4">
        <button
          onClick={requestPermission}
          className="bg-white text-indigo-600 px-4 py-1.5 rounded-md text-sm font-medium hover:bg-indigo-50 transition-colors"
        >
          Enable Notifications
        </button>
        <button
          onClick={dismissBanner}
          className="text-indigo-200 hover:text-white transition-colors"
          aria-label="Dismiss"
        >
          <X className="h-5 w-5" />
        </button>
      </div>
    </div>
  );
}
