'use strict';
/**
 * Tourist Model — raw SQL query functions (no ORM).
 * TODO: implement
 */
const { query } = require('../config/db');

const findAll        = async () => { throw new Error('touristModel.findAll — not implemented'); };
const findById       = async (/* id */) => { throw new Error('touristModel.findById — not implemented'); };
const findByTouristId= async (/* touristId */) => { throw new Error('touristModel.findByTouristId — not implemented'); };
const create         = async (/* data */) => { throw new Error('touristModel.create — not implemented'); };
const update         = async (/* id, data */) => { throw new Error('touristModel.update — not implemented'); };
const remove         = async (/* id */) => { throw new Error('touristModel.remove — not implemented'); };

module.exports = { findAll, findById, findByTouristId, create, update, remove, query };
