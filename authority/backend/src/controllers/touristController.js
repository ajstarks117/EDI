'use strict';

const { error, success, notImplemented } = require('../utils/responseUtils');
const { query } = require('../config/db');

/**
 * GET /api/tourists/:id/safety-score
 * Calculate a safety score 0-100 based on multiple factors.
 */
const getSafetyScore = async (req, res, next) => {
  try {
    const requestedId = req.params.id;
    const tokenId = req.tourist && req.tourist.id;

    // Must be own record
    if (tokenId && tokenId !== requestedId) {
      return error(res, 'Forbidden: cannot access another tourist\'s score', 403);
    }

    let score = 0;
    const breakdown = {
      gps_active: false,
      blockchain_verified: false,
      emergency_contacts_set: false,
      sos_tested: false
    };

    // 1. Check last GPS log within 60s
    const gpsRes = await query(
      `SELECT captured_at FROM gps_logs 
       WHERE tourist_id = $1 
       ORDER BY captured_at DESC LIMIT 1`,
      [requestedId]
    );
    if (gpsRes.rows.length > 0) {
      const lastLog = new Date(gpsRes.rows[0].captured_at);
      if (Date.now() - lastLog.getTime() <= 60000) {
        score += 30;
        breakdown.gps_active = true;
      }
    }

    // 2. Check blockchain identity valid_until > NOW()
    const bcRes = await query(
      `SELECT valid_until FROM blockchain_ids 
       WHERE tourist_id = $1 
       ORDER BY issued_at DESC LIMIT 1`,
      [requestedId]
    );
    if (bcRes.rows.length > 0) {
      const validUntil = new Date(bcRes.rows[0].valid_until);
      if (validUntil.getTime() > Date.now()) {
        score += 25;
        breakdown.blockchain_verified = true;
      }
    }

    // 3. Check emergency_contacts count >= 2
    const ecRes = await query(
      `SELECT COUNT(*) as count FROM emergency_contacts 
       WHERE tourist_id = $1`,
      [requestedId]
    );
    if (parseInt(ecRes.rows[0].count, 10) >= 2) {
      score += 25;
      breakdown.emergency_contacts_set = true;
    }

    // 4. Check if at least one SOS test exists (source="test")
    const sosRes = await query(
      `SELECT id FROM sos_alerts 
       WHERE tourist_id = $1 AND source = 'test' 
       LIMIT 1`,
      [requestedId]
    );
    if (sosRes.rows.length > 0) {
      score += 20;
      breakdown.sos_tested = true;
    }

    return success(res, { score, breakdown });
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  listTourists:  notImplemented,
  getTourist:    notImplemented,
  createTourist: notImplemented,
  updateTourist: notImplemented,
  deleteTourist: notImplemented,
  getContacts:   notImplemented,
  addContact:    notImplemented,
  getSafetyScore
};
