import { useSettingsStore } from '../store/useSettingsStore';

export type Role = 'admin' | 'dispatcher' | 'analyst' | 'viewer';

export function useRBAC() {
  const { operatorProfile } = useSettingsStore();
  
  // Default to viewer if role is not recognized
  const role = (operatorProfile.role || 'viewer') as Role;

  const canManageGeofences = () => {
    return role === 'admin';
  };

  const canManageAlerts = () => {
    return role === 'admin' || role === 'dispatcher';
  };

  const canUnlockMedical = () => {
    return role === 'admin';
  };

  return {
    role,
    canManageGeofences,
    canManageAlerts,
    canUnlockMedical,
  };
}
