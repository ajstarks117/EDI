'use strict';
/**
 * Auth Service
 * Handles password hashing, JWT issuance, and Firebase token verification.
 * TODO: implement
 */

const registerAuthority = async (/* payload */) => {
  throw new Error('authService.registerAuthority — not implemented');
};

const loginAuthority = async (/* badgeId, password */) => {
  throw new Error('authService.loginAuthority — not implemented');
};

const signToken = (/* payload */) => {
  throw new Error('authService.signToken — not implemented');
};

module.exports = { registerAuthority, loginAuthority, signToken };
