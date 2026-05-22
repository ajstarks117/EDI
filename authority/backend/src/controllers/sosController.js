'use strict';

const Joi = require('joi');
const { error, success } = require('../utils/responseUtils');
const { query }          = require('../config/db');
const {
  createAlert,
  updateAlertStatus,
  broadcastWeatherAlert,
} = require('../services/sosService');

// ── Joi schema for SOS trigger ────────────────────────────────────────────────

const sosSchema = Joi.object({
  lat:              Joi.number().min(-90).max(90).required(),
  lng:              Joi.number().min(-180).max(180).required(),
  source:           Joi.string().valid('manual', 'auto', 'ai_triggered').required(),
  channel:          Joi.string().valid('internet', 'sms', 'wifi_direct', 'ble', 'audio').required(),
  battery_percent:    Joi.number().integer().min(0).max(100).optional().allow(null),
  relay_tourist_id:   Joi.string().optional().allow(null, ''),
  message:            Joi.string().optional().allow(null, ''),
  blockchain_id_hash: Joi.string().optional().allow(null, ''),
  connectivity:       Joi.string().valid('online', 'offline').optional().allow(null, ''),
  emergency_contacts: Joi.array().items(
    Joi.object({
      name: Joi.string().optional().allow(null, ''),
      phone: Joi.string().optional().allow(null, '')
    })
  ).optional()
});

// ── Handlers ──────────────────────────────────────────────────────────────────

/**
 * POST /api/alerts/sos  (verifyToken — tourist JWT)
 */
const triggerSOS = async (req, res, next) => {
  try {
    const { error: valError, value } = sosSchema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (valError) {
      const messages = valError.details.map(d => d.message).join(', ');
      return error(res, `Validation failed: ${messages}`, 400);
    }

    const touristId = req.tourist && req.tourist.id;
    if (!touristId) {
      return error(res, 'Unauthorised', 401, 'INVALID_TOKEN');
    }

    const result = await createAlert(touristId, value);
    return res.status(201).json({ id: result.id });
  } catch (err) {
    return next(err);
  }
};

/**
 * GET /api/alerts  (verifyAuthority)
 * Query params: status, priority, page (default 1), limit (default 20, max 100)
 */
const listAlerts = async (req, res, next) => {
  try {
    const page  = Math.max(1, parseInt(req.query.page  || '1',  10));
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit || '20', 10)));
    const offset = (page - 1) * limit;

    const conditions = [];
    const params     = [];

    if (req.query.status) {
      params.push(req.query.status);
      conditions.push(`sa.status = $${params.length}`);
    }
    if (req.query.priority) {
      params.push(req.query.priority);
      conditions.push(`sa.priority = $${params.length}`);
    }

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

    // Count total
    const countResult = await query(
      `SELECT COUNT(*) AS total FROM sos_alerts sa ${where}`,
      params
    );
    const total = parseInt(countResult.rows[0].total, 10);

    // Fetch page
    params.push(limit, offset);
    const { rows: alerts } = await query(
      `SELECT sa.*,
              t.tourist_id AS tourist_ref_id,
              t.full_name  AS tourist_name,
              t.phone      AS tourist_phone,
              t.nationality
         FROM sos_alerts sa
         JOIN tourists t ON t.id = sa.tourist_id
        ${where}
        ORDER BY
          CASE sa.priority
            WHEN 'critical' THEN 1
            WHEN 'medium'   THEN 2
            WHEN 'low'      THEN 3
            ELSE 4
          END,
          sa.created_at DESC
        LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    return success(res, { alerts, total, page, limit });
  } catch (err) {
    return next(err);
  }
};

/**
 * GET /api/alerts/:id  (verifyToken)
 */
const getAlert = async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT sa.*,
              t.tourist_id AS tourist_ref_id,
              t.full_name  AS tourist_name,
              t.phone      AS tourist_phone
         FROM sos_alerts sa
         JOIN tourists t ON t.id = sa.tourist_id
        WHERE sa.id = $1`,
      [req.params.id]
    );

    if (rows.length === 0) {
      return error(res, 'Alert not found', 404);
    }
    return success(res, rows[0]);
  } catch (err) {
    return next(err);
  }
};

/**
 * PATCH /api/alerts/:id/status  (verifyAuthority)
 * Body: { status: "acknowledged" | "resolved", authority_id? }
 */
const updateStatus = async (req, res, next) => {
  try {
    const { status, authority_id } = req.body;

    if (!status || !['acknowledged', 'resolved'].includes(status)) {
      return error(res, 'status must be "acknowledged" or "resolved"', 400);
    }

    const updated = await updateAlertStatus(req.params.id, status, authority_id || null);

    if (!updated) {
      return error(res, 'Alert not found', 404);
    }

    return success(res, updated);
  } catch (err) {
    return next(err);
  }
};

/**
 * POST /api/alerts/:id/assign  (verifyAuthority)
 * Assign an authority to a specific alert.
 */
const assignAuthority = async (req, res, next) => {
  try {
    const { authority_id } = req.body;
    if (!authority_id) {
      return error(res, 'authority_id is required', 400);
    }

    const { rows } = await query(
      `UPDATE sos_alerts SET authority_id = $1 WHERE id = $2 RETURNING *`,
      [authority_id, req.params.id]
    );

    if (rows.length === 0) {
      return error(res, 'Alert not found', 404);
    }
    return success(res, rows[0]);
  } catch (err) {
    return next(err);
  }
};

/**
 * POST /api/alerts/weather  (verifyAuthority)
 * Broadcast WEATHER_ALERT to all connected WebSocket clients.
 * Body: any weather alert payload
 */
const weatherAlert = async (req, res, next) => {
  try {
    const payload = {
      ...req.body,
      issued_by:  req.authority && req.authority.badge_id,
      issued_at:  new Date().toISOString(),
    };

    broadcastWeatherAlert(payload);
    return res.status(200).json({ broadcast: true, payload });
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  triggerSOS,
  listAlerts,
  getAlert,
  updateStatus,
  assignAuthority,
  weatherAlert,
};
