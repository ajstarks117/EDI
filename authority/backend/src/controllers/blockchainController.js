'use strict';

const { error, success } = require('../utils/responseUtils');
const {
  generateIdentity,
  verifyByTouristId,
  getIdentityByTouristDbId,
} = require('../services/blockchainService');
const { query } = require('../config/db');

/**
 * POST /api/blockchain/issue  (verifyToken + requireAuthority)
 * Manually issue / re-issue a blockchain identity for a tourist.
 * Body: { tourist_id }  — the string ID like IND-XXXXXX-XX
 */
const issueIdentity = async (req, res, next) => {
  try {
    const { tourist_id } = req.body;
    if (!tourist_id) {
      return error(res, 'tourist_id is required', 400);
    }

    // Fetch tourist + emergency contacts
    const { rows } = await query(
      `SELECT t.*,
              COALESCE(
                json_agg(
                  json_build_object('name', ec.name, 'phone', ec.phone, 'relation', ec.relation)
                  ORDER BY ec.name
                ) FILTER (WHERE ec.id IS NOT NULL),
                '[]'
              ) AS emergency_contacts
         FROM tourists t
         LEFT JOIN emergency_contacts ec ON ec.tourist_id = t.id
        WHERE t.tourist_id = $1
        GROUP BY t.id`,
      [tourist_id]
    );

    if (rows.length === 0) {
      return error(res, 'Tourist not found', 404);
    }

    const result = await generateIdentity(rows[0]);
    return res.status(201).json(result);
  } catch (err) {
    return next(err);
  }
};

/**
 * POST /api/blockchain/verify  (verifyToken)
 * Verify by tourist_id string or identity_hash in body.
 * Body: { tourist_id } | { identity_hash }
 */
const verifyIdentity = async (req, res, next) => {
  try {
    const { tourist_id, identity_hash } = req.body;

    let resolvedTouristId = tourist_id;

    // If only identity_hash provided, look up the tourist_id from blockchain_ids
    if (!resolvedTouristId && identity_hash) {
      const { rows } = await query(
        'SELECT tourist_ref_id FROM blockchain_ids WHERE identity_hash = $1 LIMIT 1',
        [identity_hash]
      );
      if (rows.length === 0) {
        return error(res, 'Tourist ID not found', 404);
      }
      resolvedTouristId = rows[0].tourist_ref_id;
    }

    if (!resolvedTouristId) {
      return error(res, 'tourist_id or identity_hash is required', 400);
    }

    const result = await verifyByTouristId(resolvedTouristId);
    if (result === null) {
      return error(res, 'Tourist ID not found', 404);
    }

    return res.status(200).json(result);
  } catch (err) {
    return next(err);
  }
};

/**
 * GET /api/blockchain/tourist/:touristId  (verifyToken)
 * Get identity record for a tourist — used by the authority dashboard.
 * :touristId is the DB UUID.
 */
const getTouristIdentity = async (req, res, next) => {
  try {
    const record = await getIdentityByTouristDbId(req.params.touristId);
    if (!record) {
      return error(res, 'No blockchain identity found for this tourist', 404);
    }
    return success(res, record);
  } catch (err) {
    return next(err);
  }
};

/**
 * GET /api/blockchain/verify/:touristId  (NO auth — offline QR scan)
 * Verifies a tourist identity by re-deriving the hash from live DB state.
 */
const verifyByQr = async (req, res, next) => {
  try {
    const result = await verifyByTouristId(req.params.touristId);

    if (result === null) {
      return error(res, 'Tourist ID not found', 404);
    }

    return res.status(200).json(result);
  } catch (err) {
    return next(err);
  }
};

/**
 * GET /api/tourists/:id/identity  (verifyToken)
 * A tourist fetches their own stored blockchain record.
 * :id is the DB UUID from the JWT (req.tourist.id).
 */
const getTouristOwnIdentity = async (req, res, next) => {
  try {
    // Tourists may only fetch their own record
    const requestedId = req.params.id;
    const tokenId     = req.tourist && req.tourist.id;

    if (tokenId && tokenId !== requestedId) {
      return error(res, 'Forbidden: cannot access another tourist\'s identity', 403);
    }

    const record = await getIdentityByTouristDbId(requestedId);
    if (!record) {
      return error(res, 'No blockchain identity found', 404);
    }
    return success(res, record);
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  issueIdentity,
  verifyIdentity,
  getTouristIdentity,
  verifyByQr,
  getTouristOwnIdentity,
};
