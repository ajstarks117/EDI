'use strict';

const rateLimit = require('express-rate-limit');

/** Default rate limit — 100 req / 15 min / IP */
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests. Please try again later.' },
});

/** Strict limiter for auth routes — 5 req / 15 min / IP */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many authentication attempts. Please try again later.' },
});

/** Relaxed limiter for high-frequency GPS batch uploads. */
const trackingLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Tracking rate limit exceeded.' },
});

/** Dedicated limiter for SOS — 10 SOS / 60 min / tourist token */
const sosLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 60 minutes
  max: 10,
  keyGenerator: (req) => {
    // If authenticated, limit by tourist ID, otherwise fallback to IP
    return req.tourist ? req.tourist.id : req.ip;
  },
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'SOS rate limit exceeded. If this is a genuine emergency please call local services.' },
});

/** AI Chat Limiter — 10 req / 60 min / tourist token */
const aiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 60 minutes
  max: 10,
  keyGenerator: (req) => {
    return req.tourist ? req.tourist.id : req.ip;
  },
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'AI Chat rate limit exceeded. Please try again later.' },
});

module.exports = { generalLimiter, authLimiter, trackingLimiter, sosLimiter, aiLimiter };
