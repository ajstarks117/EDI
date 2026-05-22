'use strict';

const Joi = require('joi');
const { error, success, notImplemented } = require('../utils/responseUtils');
const { processQuery } = require('../services/aiService');
const { query } = require('../config/db');

const chatSchema = Joi.object({
  message: Joi.string().min(1).max(1000).required(),
  lat: Joi.number().min(-90).max(90).optional().allow(null),
  lng: Joi.number().min(-180).max(180).optional().allow(null),
  intent: Joi.string().optional().allow(null, '')
});

/**
 * POST /api/ai/chat
 */
const chat = async (req, res, next) => {
  try {
    const { error: valError, value } = chatSchema.validate(req.body, { abortEarly: false, stripUnknown: true });
    if (valError) {
      const messages = valError.details.map(d => d.message).join(', ');
      return error(res, `Validation failed: ${messages}`, 400);
    }

    const { message, lat, lng, intent } = value;
    const touristDbId = req.tourist && req.tourist.id;
    if (!touristDbId) return error(res, 'Unauthorised', 401, 'INVALID_TOKEN');

    // Fetch tourist details
    const touristResult = await query(
      `SELECT full_name, blood_group, medical_conditions, is_active FROM tourists WHERE id = $1`,
      [touristDbId]
    );

    if (touristResult.rows.length === 0) {
      return error(res, 'Tourist not found', 404);
    }
    
    const tourist = touristResult.rows[0];

    const result = await processQuery(tourist, message, lat, lng);

    // Override intent if provided by user
    if (intent && result.intent === 'chat') {
      result.intent = intent;
    }

    return success(res, result);
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  chat,
  predictRiskScore: notImplemented,
  summariseAlert:   notImplemented,
  getSafeRoute:     notImplemented,
};
