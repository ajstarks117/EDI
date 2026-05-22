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

/**
 * GET /api/tourists
 * Query: ?region=...
 * Returns a dictionary of tourist states for the Control Centre.
 */
const listTourists = async (req, res, next) => {
  try {
    const { region } = req.query;
    let whereClause = '';
    const params = [];
    if (region) {
      params.push(region);
      whereClause = `WHERE t.region_code = $1 AND t.is_active = true`;
    } else {
      whereClause = `WHERE t.is_active = true`;
    }

    // 1. Fetch base tourists with identity and contact info
    const touristsRes = await query(`
      SELECT t.id, t.tourist_id, t.full_name, t.profile_photo_url, t.nationality, t.languages, 
             t.blood_group, t.medical_conditions,
             (SELECT phone FROM emergency_contacts ec WHERE ec.tourist_id = t.id LIMIT 1) as ec_phone,
             (SELECT id FROM blockchain_ids bi WHERE bi.tourist_id = t.id AND valid_until > NOW() LIMIT 1) as has_identity
      FROM tourists t
      ${whereClause}
    `, params);

    // 2. Fetch latest GPS trails for these tourists
    // We get the last 5 logs for each tourist
    const gpsRes = await query(`
      SELECT gl.tourist_id, gl.lat, gl.lng, gl.captured_at
      FROM (
        SELECT tourist_id, lat, lng, captured_at,
               row_number() OVER (PARTITION BY tourist_id ORDER BY captured_at DESC) as rn
        FROM gps_logs
      ) gl
      WHERE gl.rn <= 5
      ORDER BY gl.tourist_id, gl.captured_at ASC
    `);

    // Group GPS by tourist
    const trails = {};
    const latestGps = {};
    for (const log of gpsRes.rows) {
      if (!trails[log.tourist_id]) trails[log.tourist_id] = [];
      trails[log.tourist_id].push([log.lng, log.lat]); // [lng, lat]
      latestGps[log.tourist_id] = log; // Ascending order means the last one processed is the latest
    }

    const resultDict = {};

    for (const t of touristsRes.rows) {
      // Map medical text to structured JSON if possible, otherwise dump into conditions
      let medicalInfo = {
        bloodType: t.blood_group || "Unknown",
        allergies: [],
        conditions: [],
        medications: []
      };

      if (t.medical_conditions) {
        try {
          const parsed = JSON.parse(t.medical_conditions);
          medicalInfo = { ...medicalInfo, ...parsed };
        } catch (e) {
          // If not JSON, just add it as a general condition string
          medicalInfo.conditions.push(t.medical_conditions);
        }
      }

      const recentGps = latestGps[t.id];
      const trail = trails[t.id] || [];
      
      // Determine status safely. If we had a specific field, we'd use it. Defaults to 'safe'.
      let status = 'safe';
      
      resultDict[t.tourist_id] = {
        id: t.tourist_id,
        lat: recentGps ? recentGps.lat : 0,
        lng: recentGps ? recentGps.lng : 0,
        lastUpdated: recentGps ? new Date(recentGps.captured_at).getTime() : null,
        status: status,
        trail: trail,
        name: t.full_name,
        photo: t.profile_photo_url || `https://i.pravatar.cc/150?u=${t.tourist_id}`,
        nationality: t.nationality || "Unknown",
        languages: t.languages || ["English"],
        emergencyContact: t.ec_phone || "",
        medicalInfo: medicalInfo,
        isIdentityVerified: !!t.has_identity
      };
    }

    return res.status(200).json(resultDict); // Contract directly expects the dictionary, bypassing standard success wrap to be safe.
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  listTourists,
  getTourist:    notImplemented,
  createTourist: notImplemented,
  updateTourist: notImplemented,
  deleteTourist: notImplemented,
  getContacts:   notImplemented,
  addContact:    notImplemented,
  getSafetyScore
};
