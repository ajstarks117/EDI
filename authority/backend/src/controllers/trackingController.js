'use strict';

const Joi = require('joi');
const { error, success } = require('../utils/responseUtils');
const { query } = require('../config/db');
const { broadcastToAuthorities } = require('../websocket/wsServer');
const WS_EVENTS = require('../websocket/wsEvents');
const { GPS_BATCH_MAX } = require('../config/constants');

const locationSchema = Joi.object({
  lat: Joi.number().min(-90).max(90).required(),
  lng: Joi.number().min(-180).max(180).required(),
  accuracy: Joi.number().optional().allow(null),
  captured_at: Joi.date().iso().required(),
});

const batchSchema = Joi.object({
  positions: Joi.array().items(locationSchema).min(1).max(GPS_BATCH_MAX || 500).required()
});

/**
 * POST /api/tracking/batch-sync
 */
const batchSync = async (req, res, next) => {
  try {
    const { error: valError, value } = batchSchema.validate(req.body, { abortEarly: false, stripUnknown: true });

    if (valError) {
      const messages = valError.details.map(d => d.message).join(', ');
      return error(res, `Validation failed: ${messages}`, 400);
    }

    const touristDbId = req.tourist && req.tourist.id;
    if (!touristDbId) return error(res, 'Unauthorised', 401, 'INVALID_TOKEN');

    const positions = value.positions;
    const flatParams = [];
    
    // BATCH INSERT — single parameterised query
    const valuesClause = positions.map((p, i) => {
      flatParams.push(touristDbId, p.lat, p.lng, p.accuracy || null, p.captured_at);
      const base = i * 5;
      return `($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5})`;
    }).join(',');

    await query(
      `INSERT INTO gps_logs (tourist_id, lat, lng, accuracy, captured_at)
       VALUES ${valuesClause}
       ON CONFLICT DO NOTHING`,
      flatParams
    );

    const latestPos = positions[positions.length - 1];

    broadcastToAuthorities(WS_EVENTS.TOURIST_LOCATION, {
      id: req.tourist.tourist_id,
      lat: latestPos.lat,
      lng: latestPos.lng,
      status: 'safe' // Default status per contract
    });

    return success(res, { saved: positions.length });
  } catch (err) {
    return next(err);
  }
};

/**
 * GET /api/tracking/active-tourists
 */
const getActiveTourists = async (req, res, next) => {
  try {
    const { rows } = await query(`
      SELECT DISTINCT ON (t.id) 
        t.tourist_id, t.full_name, t.blood_group,
        g.lat, g.lng, g.captured_at
      FROM tourists t 
      JOIN gps_logs g ON g.tourist_id = t.id
      WHERE g.captured_at > NOW() - INTERVAL '2 hours' 
        AND t.is_active = true
      ORDER BY t.id, g.captured_at DESC
    `);
    
    return success(res, { active_tourists: rows });
  } catch (err) {
    return next(err);
  }
};

/**
 * GET /api/tracking/:touristId/trail
 */
const getTrail = async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit, 10) || 1000;
    const { from, to } = req.query;
    
    // Convert public tourist_id to DB id
    const touristResult = await query('SELECT id FROM tourists WHERE tourist_id = $1', [req.params.touristId]);
    if (touristResult.rows.length === 0) return error(res, 'Tourist not found', 404);
    
    const dbId = touristResult.rows[0].id;
    
    const conditions = ['tourist_id = $1'];
    const params = [dbId];
    
    if (from) {
      params.push(from);
      conditions.push(`captured_at >= $${params.length}`);
    }
    if (to) {
      params.push(to);
      conditions.push(`captured_at <= $${params.length}`);
    }
    
    params.push(limit);
    
    const whereClause = conditions.join(' AND ');
    const { rows } = await query(
      `SELECT lat, lng, accuracy, captured_at 
       FROM gps_logs 
       WHERE ${whereClause} 
       ORDER BY captured_at ASC 
       LIMIT $${params.length}`,
      params
    );
    
    return success(res, { trail: rows, count: rows.length });
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  batchSync,
  getActiveTourists,
  getTrail
};
