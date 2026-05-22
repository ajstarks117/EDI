'use strict';

/**
 * Standardised API response helpers.
 *
 * Every response from TravelTrek has the shape:
 *   { success: boolean, message: string, data?: any, meta?: any }
 */

/**
 * Send a successful JSON response.
 * @param {import('express').Response} res
 * @param {number}  statusCode  - HTTP status (default 200)
 * @param {string}  message     - Human-readable description
 * @param {any}     [data]      - Payload
 * @param {object}  [meta]      - Pagination / extra metadata
 */
const sendSuccess = (res, statusCode = 200, message = 'OK', data = null, meta = null) => {
  const body = { success: true, message };
  if (data  !== null) body.data = data;
  if (meta  !== null) body.meta = meta;
  return res.status(statusCode).json(body);
};

/**
 * Send an error JSON response.
 * @param {import('express').Response} res
 * @param {number}  statusCode
 * @param {string}  message
 * @param {any}     [details]  - Optional extra detail (e.g. validation fields)
 */
const sendError = (res, statusCode = 500, message = 'Internal Server Error', details = null) => {
  const body = { success: false, message };
  if (details !== null) body.details = details;
  return res.status(statusCode).json(body);
};

/**
 * Create a plain Error object with an attached statusCode.
 * Used by middleware / services that propagate to the global error handler.
 * @param {number} statusCode
 * @param {string} message
 * @returns {Error & { statusCode: number }}
 */
const createError = (statusCode, message) => {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
};

/**
 * 501 Not Implemented stub — used by all route stubs.
 */
const notImplemented = (_req, res) =>
  sendError(res, 501, 'Not implemented yet.');

const success = (res, data, status = 200) => {
  return res.status(status).json(data);
};

const error = (res, message, status = 400, code = null) => {
  const body = { error: message };
  if (code !== null) {
    body.code = code;
  }
  return res.status(status).json(body);
};

module.exports = {
  sendSuccess,
  sendError,
  createError,
  notImplemented,
  success,
  error,
};
