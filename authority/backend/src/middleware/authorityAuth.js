'use strict';

const { verifyToken } = require('./auth');
const { error } = require('../utils/responseUtils');

const AUTHORITY_ROLES = new Set(['officer', 'supervisor', 'admin']);

/**
 * Authority authorization middleware.
 *
 * Chains verifyToken first, then verifies that req.authority.role exists.
 * If not authority token: returns 403 { error: "Authority access required" }.
 */
const verifyAuthority = (req, res, next) => {
  verifyToken(req, res, (err) => {
    if (err) return next(err);

    if (req.tourist) {
      req.authority = req.tourist;
    }

    if (!req.authority || !req.authority.role) {
      return error(res, 'Authority access required', 403);
    }

    return next();
  });
};

const requireAuthority = verifyAuthority;

module.exports = {
  verifyAuthority,
  requireAuthority,
  AUTHORITY_ROLES,
};
