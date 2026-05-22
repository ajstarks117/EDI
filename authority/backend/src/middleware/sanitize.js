'use strict';

/**
 * Middleware to sanitize incoming request bodies by stripping HTML tags.
 */
const sanitize = (req, res, next) => {
  if (req.body && Object.keys(req.body).length > 0) {
    try {
      // Strip HTML tags using regex over the stringified JSON
      const sanitizedString = JSON.stringify(req.body).replace(/<[^>]*>/g, '');
      req.body = JSON.parse(sanitizedString);
    } catch (err) {
      console.warn('[sanitize] Error sanitizing request body:', err.message);
    }
  }
  next();
};

module.exports = { sanitize };
