'use strict';
// ─── Blockchain Routes  /api/blockchain/* ────────────────────────────────────
const router = require('express').Router();
const { verifyToken }       = require('../middleware/auth');
const { verifyAuthority }   = require('../middleware/authorityAuth');
const blockchainController  = require('../controllers/blockchainController');

// ── No-auth route (must be declared BEFORE verifyToken-guarded routes) ─────────

// Offline QR scan — verifies a tourist identity by re-deriving hash from DB.
// Returns 200 { verified, tourist, block_hash } or { verified:false, tamper_detected:true }
router.get('/verify/:touristId', blockchainController.verifyByQr);

// ── Authenticated routes ────────────────────────────────────────────────────────

// (Re-)issue a blockchain identity for a tourist — authority only
router.post('/issue',
  verifyToken, verifyAuthority,
  blockchainController.issueIdentity
);

// Verify by tourist_id or identity_hash in body — authenticated users
router.post('/verify',
  verifyToken,
  blockchainController.verifyIdentity
);

// Authority: get stored identity record for any tourist (by DB UUID)
router.get('/tourist/:touristId',
  verifyToken,
  blockchainController.getTouristIdentity
);

module.exports = router;
