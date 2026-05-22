'use strict';

/**
 * Global Express error handler.
 *
 * In development, logs the stack trace and returns standard error details.
 * In production, returns status 500 with a generic message and never exposes stack traces.
 */
const errorHandler = (err, req, res, next) => {
  const isProd = process.env.NODE_ENV === 'production';
  
  if (!isProd) {
    console.error(err.stack || err);
  }

  const statusCode = isProd ? 500 : (err.statusCode || err.status || 500);
  const message = isProd ? 'Internal Server Error' : (err.message || 'An unexpected error occurred.');

  const response = {
    error: message,
  };

  if (!isProd) {
    response.stack = err.stack;
  }

  return res.status(statusCode).json(response);
};

module.exports = { errorHandler };
