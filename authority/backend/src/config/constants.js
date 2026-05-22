'use strict';

// ─── API Endpoint Paths ───────────────────────────────────────────────────────
const SOS_ENDPOINT               = '/api/alerts/sos';
const BLOCKCHAIN_VERIFY_ENDPOINT = '/api/blockchain/verify';
const GEOFENCE_ZONES_ENDPOINT    = '/api/geofence/zones';

// ─── Auth ─────────────────────────────────────────────────────────────────────
const JWT_EXPIRY = '24h';

// ─── SOS / Alert Rules ────────────────────────────────────────────────────────
/** Minutes before an unacknowledged SOS is escalated to high priority */
const SOS_PRIORITY_ESCALATION_MINUTES = 30;

// ─── GPS Tracking ─────────────────────────────────────────────────────────────
/** Maximum number of GPS log entries accepted in a single batch upload */
const GPS_BATCH_MAX = 500;

// ─── Tourist Identity ─────────────────────────────────────────────────────────
const TOURIST_ID_PREFIX = 'IND';

// ─── SOS Status / Priority Enums ─────────────────────────────────────────────
const SOS_STATUS   = Object.freeze({ ACTIVE: 'active', RESOLVED: 'resolved', DISMISSED: 'dismissed' });
const SOS_PRIORITY = Object.freeze({ LOW: 'low', MEDIUM: 'medium', HIGH: 'high', CRITICAL: 'critical' });

// ─── Alert Sources ────────────────────────────────────────────────────────────
const SOS_SOURCE  = Object.freeze({ APP: 'app', WEARABLE: 'wearable', RELAY: 'relay', MANUAL: 'manual' });
const SOS_CHANNEL = Object.freeze({ DIRECT: 'direct', MESH: 'mesh', SMS: 'sms' });

module.exports = Object.freeze({
  // Endpoints
  SOS_ENDPOINT,
  BLOCKCHAIN_VERIFY_ENDPOINT,
  GEOFENCE_ZONES_ENDPOINT,
  // Auth
  JWT_EXPIRY,
  // Rules / Limits
  SOS_PRIORITY_ESCALATION_MINUTES,
  GPS_BATCH_MAX,
  // Identity
  TOURIST_ID_PREFIX,
  // Enums
  SOS_STATUS,
  SOS_PRIORITY,
  SOS_SOURCE,
  SOS_CHANNEL,
  // WebSocket event name map — all 5 event keys defined here
  WS_EVENTS: { NEW_SOS: 'sos:new', SOS_UPDATE: 'sos:update', TOURIST_LOCATION: 'tourist:location', ZONE_UPDATE: 'zone:update', WEATHER_ALERT: 'alert:weather' },
});
