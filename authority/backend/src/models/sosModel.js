'use strict';
/**
 * SOS Alert Model — raw SQL query functions.
 * TODO: implement
 */
const { query } = require('../config/db');

const create     = async (/* data */) => { throw new Error('sosModel.create — not implemented'); };
const findAll    = async (/* filters */) => { throw new Error('sosModel.findAll — not implemented'); };
const findById   = async (/* id */) => { throw new Error('sosModel.findById — not implemented'); };
const updateStatus = async (/* id, status */) => { throw new Error('sosModel.updateStatus — not implemented'); };
const assign     = async (/* id, authorityId */) => { throw new Error('sosModel.assign — not implemented'); };

module.exports = { create, findAll, findById, updateStatus, assign, query };
