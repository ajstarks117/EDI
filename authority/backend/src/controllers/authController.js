'use strict';

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const admin = require('../config/firebase');
const { query } = require('../config/db');
const { JWT_SECRET } = require('../config/env');
const { success, error, notImplemented } = require('../utils/responseUtils');

const { registerTourist } = require('../services/registrationService');

const register = async (req, res, next) => {
  try {
    const result = await registerTourist(req.body, req.file);
    return res.status(201).json(result);
  } catch (err) {
    if (err.statusCode === 409) {
      return error(res, err.message, 409, err.code);
    }
    return next(err);
  }
};

const login = notImplemented;
const logout = notImplemented;

const authorityLogin = async (req, res, next) => {
  try {
    const { badge_id, password } = req.body;
    if (!badge_id || !password) {
      return error(res, 'Invalid credentials', 401);
    }

    const { rows } = await query('SELECT * FROM authorities WHERE badge_id = $1', [badge_id]);
    if (rows.length === 0) {
      return error(res, 'Invalid credentials', 401);
    }

    const authority = rows[0];
    const isMatch = await bcrypt.compare(password, authority.password_hash);
    if (!isMatch) {
      return error(res, 'Invalid credentials', 401);
    }

    const payload = {
      authority_id: authority.id,
      badge_id: authority.badge_id,
      role: authority.role,
      type: 'authority',
    };

    const token = jwt.sign(payload, process.env.JWT_SECRET || JWT_SECRET, { expiresIn: '24h' });

    return success(res, {
      token,
      authority: {
        id: authority.id,
        badge_id: authority.badge_id,
        full_name: authority.full_name,
        role: authority.role,
        jurisdiction: authority.jurisdiction,
      },
    });
  } catch (err) {
    return next(err);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    let token = req.headers.authorization;
    if (token && token.startsWith('Bearer ')) {
      token = token.slice(7);
    } else {
      token = req.body.token;
    }

    if (!token) {
      return error(res, 'Unauthorised', 401, 'INVALID_TOKEN');
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET || JWT_SECRET, { ignoreExpiration: true });
    } catch (err) {
      return error(res, 'Unauthorised', 401, 'INVALID_TOKEN');
    }

    const nowSeconds = Math.floor(Date.now() / 1000);
    if (!decoded.iat || (nowSeconds - decoded.iat) >= 7 * 24 * 60 * 60) {
      return error(res, 'Session too old, re-login required', 401);
    }

    const { iat, exp, ...payload } = decoded;
    const newToken = jwt.sign(payload, process.env.JWT_SECRET || JWT_SECRET, { expiresIn: '24h' });

    return success(res, { token: newToken });
  } catch (err) {
    return next(err);
  }
};

const verifyFirebaseToken = async (req, res, next) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return error(res, 'ID Token is required', 400);
    }

    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return success(res, {
      uid: decodedToken.uid,
      phone_number: decodedToken.phone_number || null,
      verified: true,
    });
  } catch (err) {
    return error(res, err.message, 401);
  }
};

module.exports = {
  register,
  login,
  logout,
  authorityLogin,
  refreshToken,
  verifyFirebaseToken,
};
