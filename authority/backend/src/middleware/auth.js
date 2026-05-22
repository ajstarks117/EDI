'use strict';

const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config/env');
const { error } = require('../utils/responseUtils');

/**
 * JWT verification middleware.
 *
 * Expects:  Authorization: Bearer <token>
 * Attaches: req.tourist = { id, role, ... } (decoded payload)
 *           req.user = { id, role, ... } (decoded payload, for backward compatibility)
 *
 * On failure: return 401 { error: "Unauthorised", code: "INVALID_TOKEN" }
 * On expiry:  return 401 { error: "Token expired", code: "TOKEN_EXPIRED" }
 */
const verifyToken = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      return error(res, 'Unauthorised', 401, 'INVALID_TOKEN');
    }

    const token = authHeader.slice(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET || JWT_SECRET);

    req.tourist = decoded;
    req.user = decoded; // Keep for compatibility
    return next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return error(res, 'Token expired', 401, 'TOKEN_EXPIRED');
    }
    return error(res, 'Unauthorised', 401, 'INVALID_TOKEN');
  }
};

module.exports = { verifyToken };
