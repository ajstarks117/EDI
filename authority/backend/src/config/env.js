'use strict';

const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

/**
 * Validates the presence of required environment variables.
 * Throws immediately on startup if any are missing, so the app
 * never silently runs in a misconfigured state.
 *
 * Set SKIP_FIREBASE=true to bypass Firebase credential validation
 * during local development / CI testing.
 */
const ALWAYS_REQUIRED = [
  'DATABASE_URL',
  'JWT_SECRET',
];

const FIREBASE_REQUIRED = [
  'FIREBASE_PROJECT_ID',
  'FIREBASE_CLIENT_EMAIL',
  'FIREBASE_PRIVATE_KEY',
];

const skipFirebase = process.env.SKIP_FIREBASE === 'true';
const REQUIRED_VARS = skipFirebase
  ? ALWAYS_REQUIRED
  : [...ALWAYS_REQUIRED, ...FIREBASE_REQUIRED];

const missing = REQUIRED_VARS.filter((key) => !process.env[key]);
if (missing.length > 0) {
  throw new Error(
    `[env] Missing required environment variables: ${missing.join(', ')}\n` +
      'Check your .env file against .env.example.'
  );
}

module.exports = {
  NODE_ENV:   process.env.NODE_ENV || 'development',
  PORT:       parseInt(process.env.PORT || '3000', 10),

  // Database
  DATABASE_URL: process.env.DATABASE_URL,

  // Auth
  JWT_SECRET: process.env.JWT_SECRET,

  // Firebase Admin SDK
  SKIP_FIREBASE:        skipFirebase,
  FIREBASE_PROJECT_ID:  process.env.FIREBASE_PROJECT_ID  || '',
  FIREBASE_CLIENT_EMAIL:process.env.FIREBASE_CLIENT_EMAIL || '',
  FIREBASE_PRIVATE_KEY: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),

  // Optional integrations
  BLOCKCHAIN_RPC_URL: process.env.BLOCKCHAIN_RPC_URL || 'http://localhost:8545',
};
