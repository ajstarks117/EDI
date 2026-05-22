'use strict';

const rateLimit = require('express-rate-limit');

/** Default rate limit — applied globally. */
const defaultLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests. Please try again later.' },
});

/** Strict limiter for auth routes (login / register). */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
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

/** Dedicated limiter for SOS — should almost never throttle real emergencies. */
const sosLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'SOS rate limit exceeded. If this is a genuine emergency please call local services.' },
});

module.exports = { defaultLimiter, authLimiter, trackingLimiter, sosLimiter };
