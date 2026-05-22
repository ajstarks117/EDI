'use strict';

const Joi = require('joi');
const { error, success, notImplemented } = require('../utils/responseUtils');
const { query } = require('../config/db');
const { broadcastToAuthorities } = require('../websocket/wsServer');
const WS_EVENTS = require('../websocket/wsEvents');

const locationSchema = Joi.object({
  lat: Joi.number().min(-90).max(90).required(),
  lng: Joi.number().min(-180).max(180).required(),
  timestamp: Joi.date().iso().required(),
  accuracy: Joi.number().optional(),
  speed: Joi.number().optional(),
  heading: Joi.number().optional()
});

const batchSchema = Joi.object({
  positions: Joi.array().items(locationSchema).min(1).max(500).required()
});

/**
 * POST /api/tracking/batch
 */
const batchUpload = async (req, res, next) => {
  try {
    const { error: valError, value } = batchSchema.validate(req.body, { abortEarly: false, stripUnknown: true });

    if (valError) {
      const messages = valError.details.map(d => d.message).join(', ');
      return error(res, `Validation failed: ${messages}`, 400);
    }

    const touristId = req.tourist && req.tourist.id;
    if (!touristId) return error(res, 'Unauthorised', 401, 'INVALID_TOKEN');

    const positions = value.positions;

    // Optional: write to DB here (e.g. trackingService.saveBatch(touristId, positions))
    // We'll just do the WS broadcast as requested by the prompt for GPS integration

    // wsServer.broadcastToAuthorities(WS_EVENTS.TOURIST_LOCATION, { tourist_id, positions: gpsBatch.slice(-1) })
    broadcastToAuthorities(WS_EVENTS.TOURIST_LOCATION, {
      tourist_id: req.tourist.tourist_id || touristId, // fallback to id if tourist_id is missing
      positions: positions.slice(-1)
    });

    return success(res, { received: positions.length });
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  batchUpload,
  getLatest: notImplemented,
  getHistory: notImplemented,
};
