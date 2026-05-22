'use strict';

/**
 * Blockchain Identity Service
 *
 * Manages tourist identity hashing, blockchain_ids record issuance,
 * tamper-evident QR generation, and in-memory verification cache.
 *
 * HASH ALGORITHM — deterministic, sorted-key payload:
 *   1. Build canonical payload object (fixed keys, alphabetically sorted).
 *   2. identity_hash = sha256(JSON.stringify(sorted_payload))
 *   3. block_hash    = sha256(identity_hash + Date.now())
 *   4. qr_data       = base64(JSON.stringify({ tourist_id, block_hash,
 *                             identity_hash, issued_at, verify_url }))
 */

const { query, getClient } = require('../config/db');
const { sha256 } = require('../utils/hashUtils');

const HASH_SALT     = process.env.HASH_SALT   || 'traveltrek_default_hash_salt_12345';
const VERIFY_BASE   = process.env.VERIFY_BASE_URL || 'https://api.traveltrek.in/v1/blockchain/verify';
const TWO_YEARS_MS  = 2 * 365.25 * 24 * 60 * 60 * 1000;

// ── In-memory identity cache { tourist_id → blockchainRecord } ────────────────
// Avoids a DB round-trip on every QR scan; invalidated on new issuance.
const identityCache = new Map();

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Build the canonical, deterministically-sorted identity payload.
 * The sort order MUST be identical between issuance and verification.
 *
 * @param {object} tourist          - Row from `tourists` (must include emergency_contacts array)
 * @returns {{ sorted: object, identity_hash: string }}
 */
function buildIdentityPayload(tourist) {
  // Sort emergency contacts by name for determinism
  const sortedContacts = [...(tourist.emergency_contacts || [])].sort((a, b) =>
    JSON.stringify(a).localeCompare(JSON.stringify(b))
  );

  const payload = {
    emergency_contacts_hash: sha256(JSON.stringify(sortedContacts)),
    full_name:               tourist.full_name,
    id_document_type:        tourist.id_document_type,
    id_number_hash:          tourist.id_number_hash,
    phone_hash:              sha256(tourist.phone + HASH_SALT),
    region_code:             tourist.region_code || 'IN',
    registration_timestamp:  (tourist.created_at instanceof Date
                               ? tourist.created_at
                               : new Date(tourist.created_at)
                             ).toISOString(),
    tourist_id:              tourist.tourist_id,
  };

  // Alphabetically sort keys for canonical form
  const sorted = Object.fromEntries(Object.entries(payload).sort());
  const identity_hash = sha256(JSON.stringify(sorted));

  return { sorted, identity_hash };
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Issue a blockchain identity for a tourist.
 * Writes a row to `blockchain_ids`, caches in memory, returns full record.
 *
 * @param {object} tourist  - Full tourist row INCLUDING emergency_contacts array
 * @returns {Promise<object>}  The issued identity record
 */
const generateIdentity = async (tourist) => {
  // Step 1 & 2 — build sorted payload and compute identity_hash
  const { identity_hash } = buildIdentityPayload(tourist);

  // Step 3 — derive block_hash and timestamps
  const issuedAt   = new Date();
  const block_hash = sha256(identity_hash + issuedAt.getTime().toString());
  const validUntil = new Date(issuedAt.getTime() + TWO_YEARS_MS);

  // Step 4 — build QR data (base64 JSON blob)
  const qr_payload = {
    tourist_id:    tourist.tourist_id,
    block_hash,
    identity_hash,
    issued_at:     issuedAt.toISOString(),
    verify_url:    `${VERIFY_BASE}/${tourist.tourist_id}`,
  };
  const qr_data = Buffer.from(JSON.stringify(qr_payload)).toString('base64');

  // Step 5 — persist to blockchain_ids table
  const { rows } = await query(
    `INSERT INTO blockchain_ids
       (tourist_id, tourist_ref_id, identity_hash, block_hash, qr_data, issued_at, valid_until)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [
      tourist.id,
      tourist.tourist_id,
      identity_hash,
      block_hash,
      qr_data,
      issuedAt,
      validUntil,
    ]
  );
  const record = rows[0];

  // Step 6 — update in-memory cache
  identityCache.set(tourist.tourist_id, record);

  return {
    block_hash,
    identity_hash,
    qr_data,
    issued_at:   issuedAt.toISOString(),
    valid_until: validUntil.toISOString(),
  };
};

/**
 * Verify a tourist's blockchain identity by recomputing the identity_hash
 * from the current DB state and comparing it to the stored value.
 *
 * Returns:
 *   { verified: true,  tourist, block_hash }           — hashes match
 *   { verified: false, tamper_detected: true }         — hashes diverge
 *   null                                               — tourist_id not found
 *
 * @param {string} touristId  - The `tourist_id` string (e.g. IND-ABC123-XY)
 * @returns {Promise<object|null>}
 */
const verifyByTouristId = async (touristId) => {
  // Fetch tourist + emergency contacts in one go
  const { rows: touristRows } = await query(
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
    [touristId]
  );

  if (touristRows.length === 0) return null;

  const tourist = touristRows[0];

  // Fetch stored blockchain record
  const { rows: blockRows } = await query(
    `SELECT * FROM blockchain_ids
      WHERE tourist_ref_id = $1
      ORDER BY issued_at DESC
      LIMIT 1`,
    [touristId]
  );

  if (blockRows.length === 0) return null;

  const stored = blockRows[0];

  // Recompute identity_hash with the SAME deterministic logic
  const { identity_hash: recomputed } = buildIdentityPayload(tourist);

  if (recomputed === stored.identity_hash) {
    return {
      verified:   true,
      block_hash: stored.block_hash,
      tourist: {
        tourist_id:      tourist.tourist_id,
        full_name:       tourist.full_name,
        nationality:     tourist.nationality,
        id_document_type: tourist.id_document_type,
        region_code:     tourist.region_code || 'IN',
        issued_at:       stored.issued_at,
        valid_until:     stored.valid_until,
      },
    };
  }

  return { verified: false, tamper_detected: true };
};

/**
 * Retrieve the latest stored blockchain record for a tourist UUID (DB id).
 *
 * @param {string} touristDbId  - UUID primary key of the tourist row
 * @returns {Promise<object|null>}
 */
const getIdentityByTouristDbId = async (touristDbId) => {
  const { rows } = await query(
    `SELECT bi.*, t.tourist_id, t.full_name
       FROM blockchain_ids bi
       JOIN tourists t ON t.id = bi.tourist_id
      WHERE bi.tourist_id = $1
      ORDER BY bi.issued_at DESC
      LIMIT 1`,
    [touristDbId]
  );
  return rows.length > 0 ? rows[0] : null;
};

module.exports = {
  generateIdentity,
  verifyByTouristId,
  getIdentityByTouristDbId,
  // Expose for testing / internal use
  buildIdentityPayload,
  identityCache,
};
