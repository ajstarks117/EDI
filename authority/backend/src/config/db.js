'use strict';

const { Pool } = require('pg');
// env.js must be loaded before this module
const { DATABASE_URL, NODE_ENV } = require('./env');

const pool = new Pool({
  connectionString: DATABASE_URL,
  // Railway / Render free-tier DBs cap at 25 connections; keep headroom.
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  ssl: NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

pool.on('error', (err) => {
  console.error('[db] Unexpected pool error:', err.message);
});

/**
 * Convenience wrapper — runs a parameterised query and returns rows.
 * @param {string} text    - SQL query string with $1, $2, … placeholders
 * @param {any[]}  [params] - query parameters
 * @returns {Promise<import('pg').QueryResult>}
 */
const query = (text, params) => pool.query(text, params);

/**
 * Acquire a client from the pool for multi-statement transactions.
 * Caller is responsible for calling client.release().
 * @returns {Promise<import('pg').PoolClient>}
 */
const getClient = () => pool.connect();

module.exports = { pool, query, getClient };
