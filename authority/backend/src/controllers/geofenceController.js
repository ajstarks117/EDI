'use strict';

const Joi = require('joi');
const { error, success, notImplemented } = require('../utils/responseUtils');
const { query } = require('../config/db');
const { broadcastToAuthorities, broadcastToAllTourists } = require('../websocket/wsServer');
const WS_EVENTS = require('../websocket/wsEvents');

const zoneSchema = Joi.object({
  name: Joi.string().required(),
  zone_type: Joi.string().valid('warning', 'restricted', 'exclusion', 'safe').required(),
  polygon_coordinates: Joi.array().items(
    Joi.array().ordered(
      Joi.number().min(-180).max(180).required(),
      Joi.number().min(-90).max(90).required()
    )
  ).min(3).required(),
  advisory_text: Joi.string().optional().allow(null, '')
});

/**
 * GET /api/geofence/zones
 */
const listZones = async (req, res, next) => {
  try {
    const { rows } = await query(`
      SELECT id, name, zone_type, advisory_text, is_active, created_at, updated_at,
             ST_AsGeoJSON(geom)::jsonb AS geom
      FROM geofence_zones 
      WHERE is_active = true
    `);
    return success(res, { zones: rows });
  } catch (err) {
    return next(err);
  }
};

/**
 * POST /api/geofence/zones
 */
const createZone = async (req, res, next) => {
  try {
    const { error: valError, value } = zoneSchema.validate(req.body, { abortEarly: false, stripUnknown: true });
    if (valError) {
      const messages = valError.details.map(d => d.message).join(', ');
      return error(res, `Validation failed: ${messages}`, 400);
    }

    const { name, zone_type, polygon_coordinates, advisory_text } = value;
    
    // Create GeoJSON Polygon from coordinates
    // PostGIS expects coordinates in [lng, lat] and closed (first point == last point).
    const coords = [...polygon_coordinates];
    if (coords[0][0] !== coords[coords.length - 1][0] || coords[0][1] !== coords[coords.length - 1][1]) {
      coords.push([...coords[0]]);
    }
    
    const geom = {
      type: 'Polygon',
      coordinates: [coords]
    };

    const { rows } = await query(
      `INSERT INTO geofence_zones (name, zone_type, geom, advisory_text, created_by)
       VALUES ($1, $2, ST_GeomFromGeoJSON($3), $4, $5)
       RETURNING id, name, zone_type, advisory_text, is_active, created_at, updated_at,
         ST_AsGeoJSON(geom)::jsonb AS geom`,
      [name, zone_type, JSON.stringify(geom), advisory_text, req.authority.id]
    );

    const zone = rows[0];

    // Broadcast to all tourists and authorities
    broadcastToAuthorities(WS_EVENTS.ZONE_UPDATE, { action: 'create', zone });
    broadcastToAllTourists(WS_EVENTS.ZONE_UPDATE, { action: 'create', zone });

    return res.status(201).json({ success: true, data: { zone } });
  } catch (err) {
    return next(err);
  }
};

/**
 * PUT /api/geofence/zones/:id
 */
const updateZone = async (req, res, next) => {
  try {
    const { error: valError, value } = zoneSchema.validate(req.body, { abortEarly: false, stripUnknown: true });
    if (valError) {
      const messages = valError.details.map(d => d.message).join(', ');
      return error(res, `Validation failed: ${messages}`, 400);
    }

    const { name, zone_type, polygon_coordinates, advisory_text } = value;
    
    const coords = [...polygon_coordinates];
    if (coords[0][0] !== coords[coords.length - 1][0] || coords[0][1] !== coords[coords.length - 1][1]) {
      coords.push([...coords[0]]);
    }
    
    const geom = {
      type: 'Polygon',
      coordinates: [coords]
    };

    const { rows } = await query(
      `UPDATE geofence_zones 
       SET name = $1, zone_type = $2, geom = ST_GeomFromGeoJSON($3), advisory_text = $4, updated_at = NOW()
       WHERE id = $5
       RETURNING id, name, zone_type, advisory_text, is_active, created_at, updated_at,
         ST_AsGeoJSON(geom)::jsonb AS geom`,
      [name, zone_type, JSON.stringify(geom), advisory_text, req.params.id]
    );

    if (rows.length === 0) {
      return error(res, 'Zone not found', 404);
    }

    const zone = rows[0];
    broadcastToAuthorities(WS_EVENTS.ZONE_UPDATE, { action: 'update', zone });
    broadcastToAllTourists(WS_EVENTS.ZONE_UPDATE, { action: 'update', zone });

    return success(res, { zone });
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  listZones,
  getZone: notImplemented,
  createZone,
  updateZone,
  deleteZone: notImplemented,
  checkPoint: notImplemented,
};
