'use strict';
/**
 * GPS Log Model — raw SQL query functions.
 * TODO: implement
 */
const { query } = require('../config/db');

const insertBatch   = async (/* rows */) => { throw new Error('gpsModel.insertBatch — not implemented'); };
const getLatest     = async (/* touristId */) => { throw new Error('gpsModel.getLatest — not implemented'); };
const getHistory    = async (/* touristId, from, to */) => { throw new Error('gpsModel.getHistory — not implemented'); };

module.exports = { insertBatch, getLatest, getHistory, query };
