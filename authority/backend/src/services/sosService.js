'use strict';

/**
 * SOS Service
 *
 * createAlert(touristId, payload)  — inserts sos_alerts row, derives priority
 * escalateOverdue()                — promotes medium alerts > 30 min to critical
 * updateAlertStatus(id, status, authorityId) — PATCH status + WS broadcast
 * broadcastWeatherAlert(payload)   — sends WEATHER_ALERT to all sockets
 */

const { query }                     = require('../config/db');
const { broadcastToAuthorities, broadcastToAllTourists } = require('../websocket/wsServer');
const WS_EVENTS                     = require('../websocket/wsEvents');
const { SOS_PRIORITY_ESCALATION_MINUTES } = require('../config/constants');

// ── Priority derivation ────────────────────────────────────────────────────────

/**
 * Derive alert priority from payload fields.
 *   critical — manual trigger OR battery < 15 %
 *   medium   — non-internet channel
 *   low      — everything else
 */
const derivePriority = ({ source, channel, battery_percent }) => {
  if (source === 'manual' || (battery_percent !== undefined && battery_percent !== null && battery_percent < 15)) {
    return 'critical';
  }
  if (channel !== 'internet') {
    return 'medium';
  }
  return 'low';
};

// ── Public API ─────────────────────────────────────────────────────────────────

/**
 * Create a new SOS alert row and broadcast NEW_SOS to the authorities room.
 *
 * @param {string} touristId  - DB UUID of the tourist (from req.tourist.id)
 * @param {object} payload    - Validated Joi body
 * @returns {Promise<{ received:true, id:string, severity:string }>}
 */
const createAlert = async (touristId, payload) => {
  const {
    lat,
    lng,
    source,
    channel,
    battery_percent = null,
    relay_tourist_id = null,
  } = payload;

  // Step 1 — derive priority
  const priority = derivePriority({ source, channel, battery_percent });

  // Step 2 — persist
  const { rows } = await query(
    `WITH new_alert AS (
       INSERT INTO sos_alerts
         (tourist_id, lat, lng, source, channel, battery_percent,
          relay_tourist_id, priority, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'active')
       RETURNING *
     )
     SELECT na.*, t.full_name AS tourist_name
       FROM new_alert na
       JOIN tourists t ON t.id = na.tourist_id`,
    [touristId, lat, lng, source, channel, battery_percent, relay_tourist_id, priority]
  );

  const alert = rows[0];

  // Step 3 — broadcast to authorities
  broadcastToAuthorities(WS_EVENTS.NEW_SOS, {
    id:          alert.id,
    tourist_id:  alert.tourist_id,
    tourist_name: alert.tourist_name,
    lat:         alert.lat,
    lng:         alert.lng,
    priority:    alert.priority,
    source:      alert.source,
    channel:     alert.channel,
    created_at:  alert.created_at,
  });

  return { received: true, id: alert.id, severity: alert.priority };
};

/**
 * Escalate medium-priority alerts older than SOS_PRIORITY_ESCALATION_MINUTES
 * to critical. Called on a setInterval in index.js.
 */
const escalateOverdue = async () => {
  const thresholdMinutes = SOS_PRIORITY_ESCALATION_MINUTES;

  const { rows } = await query(
    `UPDATE sos_alerts
        SET priority = 'critical'
      WHERE priority = 'medium'
        AND status   = 'active'
        AND created_at < NOW() - ($1 || ' minutes')::INTERVAL
      RETURNING *`,
    [thresholdMinutes]
  );

  for (const alert of rows) {
    broadcastToAuthorities(WS_EVENTS.SOS_UPDATE, {
      id:         alert.id,
      priority:   'critical',
      escalated:  true,
      tourist_id: alert.tourist_id,
      updated_at: new Date().toISOString(),
    });
  }

  if (rows.length > 0) {
    console.log(`[escalation] ${rows.length} alert(s) escalated to critical.`);
  }
};

/**
 * Update an alert's status (acknowledged | resolved) and broadcast SOS_UPDATE.
 *
 * @param {string} alertId
 * @param {string} status        - 'acknowledged' | 'resolved'
 * @param {string} [authorityId] - DB UUID of authority performing the action
 * @returns {Promise<object>} Updated alert row
 */
const updateAlertStatus = async (alertId, status, authorityId = null) => {
  const { rows } = await query(
    `UPDATE sos_alerts
        SET status       = $1,
            authority_id = COALESCE($2::uuid, authority_id)
      WHERE id = $3
      RETURNING *`,
    [status, authorityId, alertId]
  );

  if (rows.length === 0) return null;

  const alert = rows[0];

  broadcastToAuthorities(WS_EVENTS.SOS_UPDATE, {
    id:           alert.id,
    status:       alert.status,
    authority_id: alert.authority_id,
    tourist_id:   alert.tourist_id,
    updated_at:   new Date().toISOString(),
  });

  return alert;
};

/**
 * Broadcast a weather alert to ALL connected WebSocket clients.
 *
 * @param {object} payload  - Arbitrary alert payload from authority
 */
const broadcastWeatherAlert = (payload) => {
  broadcastToAllTourists(WS_EVENTS.WEATHER_ALERT, payload);
};

module.exports = {
  createAlert,
  escalateOverdue,
  updateAlertStatus,
  broadcastWeatherAlert,
};
