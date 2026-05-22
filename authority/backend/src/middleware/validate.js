'use strict';

const { sendError } = require('../utils/responseUtils');

/**
 * Joi validation middleware factory.
 *
 * Usage:
 *   router.post('/route', validate(schema), controller);
 *
 * @param {import('joi').ObjectSchema} schema - Joi schema to validate against
 * @param {'body' | 'query' | 'params'} [source='body'] - req property to validate
 * @returns {import('express').RequestHandler}
 */
const validate = (schema, source = 'body') => (req, res, next) => {
  const { error, value } = schema.validate(req[source], {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    const messages = error.details.map((d) => d.message);
    return sendError(res, 422, 'Validation failed.', { fields: messages });
  }

  // Replace req[source] with the stripped / coerced value
  req[source] = value;
  return next();
};

module.exports = { validate };
