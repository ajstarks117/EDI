'use strict';

const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { getClient, query } = require('../config/db');
const { JWT_SECRET } = require('../config/env');
const { sha256 } = require('../utils/hashUtils');
const { generateIdentity } = require('./blockchainService');

const HASH_SALT = process.env.HASH_SALT || 'traveltrek_default_hash_salt_12345';

/**
 * Generate a random segment of uppercase alphanumeric characters
 * using cryptographically secure crypto.randomBytes.
 */
const generateAlphanumSegment = (length) => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const bytes = crypto.randomBytes(length);
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars[bytes[i] % chars.length];
  }
  return result;
};

/**
 * Generates a unique Tourist ID following format: IND-[6 random uppercase alphanum]-[2 alphanum]
 * Retries up to 5 times in case of collision.
 */
const getUniqueTouristId = async () => {
  let attempts = 0;
  while (attempts < 5) {
    const seg1 = generateAlphanumSegment(6);
    const seg2 = generateAlphanumSegment(2);
    const touristId = `IND-${seg1}-${seg2}`;
    
    // Check collision
    const { rows } = await query('SELECT id FROM tourists WHERE tourist_id = $1', [touristId]);
    if (rows.length === 0) {
      return touristId;
    }
    attempts++;
  }
  
  const err = new Error('Failed to generate unique Tourist ID after 5 attempts.');
  err.statusCode = 500;
  throw err;
};

/**
 * Registers a new tourist under a database transaction.
 */
const registerTourist = async (data, profilePhotoFile) => {
  const {
    full_name,
    phone,
    nationality,
    id_document_type,
    id_number,
    blood_group,
    medical_conditions,
    emergency_contacts
  } = data;

  // Step 1: Check duplicate phone
  const dupCheck = await query('SELECT id FROM tourists WHERE phone = $1', [phone]);
  if (dupCheck.rows.length > 0) {
    const err = new Error('Phone already registered');
    err.statusCode = 409;
    err.code = 'DUPLICATE_PHONE';
    throw err;
  }

  // Step 2: Generate Tourist ID
  const touristId = await getUniqueTouristId();

  // Step 3: Hash id_number
  const idNumberHash = sha256(id_number + HASH_SALT);

  // Set profile photo url if file exists
  const profilePhotoUrl = profilePhotoFile ? `/uploads/${profilePhotoFile.filename}` : null;

  // Step 4: BEGIN transaction
  const client = await getClient();
  try {
    await client.query('BEGIN');

    // Insert tourist
    const touristQuery = `
      INSERT INTO tourists (
        tourist_id, phone, full_name, nationality, id_document_type,
        id_number_hash, blood_group, medical_conditions, profile_photo_url, is_active
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id
    `;
    const touristParams = [
      touristId,
      phone,
      full_name,
      nationality,
      id_document_type,
      idNumberHash,
      blood_group || null,
      medical_conditions || null,
      profilePhotoUrl,
      true
    ];
    
    const touristResult = await client.query(touristQuery, touristParams);
    const dbTouristId = touristResult.rows[0].id;

    // Bulk insert emergency contacts
    for (const contact of emergency_contacts) {
      await client.query(
        'INSERT INTO emergency_contacts (tourist_id, name, phone, relation) VALUES ($1, $2, $3, $4)',
        [dbTouristId, contact.name, contact.phone, contact.relation]
      );
    }

    await client.query('COMMIT');

    // Step 5: Fetch inserted tourist row + contacts for identity generation
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
        WHERE t.id = $1
        GROUP BY t.id`,
      [dbTouristId]
    );
    const touristRow = touristRows[0];

    // Step 6: Generate blockchain identity (writes to blockchain_ids, caches in memory)
    const identityResult = await generateIdentity(touristRow);

    // Step 7: Sign JWT token
    const tokenPayload = {
      id: dbTouristId,
      tourist_id: touristId,
      full_name,
      phone,
      type: 'tourist'
    };
    const token = jwt.sign(tokenPayload, process.env.JWT_SECRET || JWT_SECRET, { expiresIn: '7d' });

    return {
      tourist_id: touristId,
      id: dbTouristId,
      full_name,
      token,
      ...identityResult,   // block_hash, identity_hash, qr_data, issued_at, valid_until
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  registerTourist
};
