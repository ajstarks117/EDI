'use strict';
/**
 * Authority Model — raw SQL query functions.
 * TODO: implement
 */
const { query } = require('../config/db');

const findByBadgeId = async (/* badgeId */) => { throw new Error('authorityModel.findByBadgeId — not implemented'); };
const findById      = async (/* id */) => { throw new Error('authorityModel.findById — not implemented'); };
const create        = async (/* data */) => { throw new Error('authorityModel.create — not implemented'); };

module.exports = { findByBadgeId, findById, create, query };
