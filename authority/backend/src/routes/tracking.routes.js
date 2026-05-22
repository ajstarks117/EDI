'use strict';
// ─── Tracking Routes  /api/tracking/* ────────────────────────────────────────
const router = require('express').Router();
const { verifyToken }      = require('../middleware/auth');
const { requireAuthority } = require('../middleware/authorityAuth');
const { trackingLimiter }  = require('../middleware/rateLimiter');
const trackingController   = require('../controllers/trackingController');

// Tourist uploads GPS logs (batch)
router.post('/batch-sync', verifyToken, trackingLimiter, trackingController.batchSync);

// Authority: get active tourists (latest location within 2 hours)
router.get('/active-tourists', verifyAuthority, trackingController.getActiveTourists);

// Authority: full GPS history for a tourist
router.get('/:touristId/trail', verifyAuthority, trackingController.getTrail);

// Alias /history to /trail for backwards compatibility if needed, or remove
// Currently we just use the 3 endpoints requested.

module.exports = router;
