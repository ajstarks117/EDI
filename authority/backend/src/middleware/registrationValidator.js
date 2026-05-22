'use strict';

const Joi = require('joi');
const { error } = require('../utils/responseUtils');

const registrationSchema = Joi.object({
  full_name: Joi.string().min(2).max(100).required(),
  phone: Joi.string().pattern(/^\+\d{10,15}$/).required(), // E.164 format, supporting +91XXXXXXXXXX
  nationality: Joi.string().required(),
  id_document_type: Joi.string().valid('aadhaar', 'passport', 'driving_license').required(),
  id_number: Joi.string().required(),
  blood_group: Joi.string().valid('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-').optional(),
  medical_conditions: Joi.string().max(500).optional(),
  emergency_contacts: Joi.array().items(
    Joi.object({
      name: Joi.string().required(),
      phone: Joi.string().pattern(/^\+\d{10,15}$/).required(),
      relation: Joi.string().required()
    })
  ).min(2).required(),
  firebase_uid: Joi.string().required()
});

const validateRegistration = (req, res, next) => {
  // Gracefully parse JSON stringified emergency_contacts from multipart/form-data
  if (typeof req.body.emergency_contacts === 'string') {
    try {
      req.body.emergency_contacts = JSON.parse(req.body.emergency_contacts);
    } catch (err) {
      return error(res, 'emergency_contacts must be a valid JSON array', 400);
    }
  }

  const { error: valError, value } = registrationSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true
  });

  if (valError) {
    const messages = valError.details.map(d => d.message).join(', ');
    return error(res, `Validation failed: ${messages}`, 400);
  }

  req.body = value;
  return next();
};

module.exports = {
  validateRegistration
};
