'use strict';

const constants = require('../config/constants');

/**
 * All WebSocket event name constants, re-exported from constants.js
 * for convenient import by WebSocket consumers.
 *
 * Usage:
 *   const { NEW_SOS, TOURIST_LOCATION } = require('./wsEvents');
 */
module.exports = constants.WS_EVENTS;
