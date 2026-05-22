'use strict';
/**
 * Blockchain Identity Model — raw SQL query functions.
 * TODO: implement
 */
const { query } = require('../config/db');

const create              = async (/* data */) => { throw new Error('blockchainModel.create — not implemented'); };
const findByTouristId     = async (/* touristId */) => { throw new Error('blockchainModel.findByTouristId — not implemented'); };
const findByIdentityHash  = async (/* hash */) => { throw new Error('blockchainModel.findByIdentityHash — not implemented'); };

module.exports = { create, findByTouristId, findByIdentityHash, query };
