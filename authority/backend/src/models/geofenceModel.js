'use strict';
/**
 * Geofence Zone Model — raw SQL query functions.
 * TODO: implement
 */
const { query } = require('../config/db');

const findAll   = async () => { throw new Error('geofenceModel.findAll — not implemented'); };
const findById  = async (/* id */) => { throw new Error('geofenceModel.findById — not implemented'); };
const create    = async (/* data */) => { throw new Error('geofenceModel.create — not implemented'); };
const update    = async (/* id, data */) => { throw new Error('geofenceModel.update — not implemented'); };
const remove    = async (/* id */) => { throw new Error('geofenceModel.remove — not implemented'); };

module.exports = { findAll, findById, create, update, remove, query };
