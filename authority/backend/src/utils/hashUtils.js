'use strict';

const crypto = require('crypto');

/**
 * Returns the SHA-256 hex digest of a UTF-8 string.
 * @param {string} value
 * @returns {string} 64-char hex string
 */
const sha256 = (value) =>
  crypto.createHash('sha256').update(String(value), 'utf8').digest('hex');

/**
 * Returns the SHA-256 hex digest of a JSON-serialisable object.
 * Keys are sorted for deterministic hashing.
 * @param {object} obj
 * @returns {string}
 */
const sha256Object = (obj) => {
  const sorted = JSON.stringify(obj, Object.keys(obj).sort());
  return sha256(sorted);
};

/**
 * Generates a simple block hash by chaining previousHash + payload hash.
 * @param {string} previousHash
 * @param {object} payload
 * @returns {string}
 */
const computeBlockHash = (previousHash, payload) =>
  sha256(`${previousHash}${sha256Object(payload)}`);

module.exports = { sha256, sha256Object, computeBlockHash };
