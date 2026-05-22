'use strict';
// ─── Tracking Routes  /api/tracking/* ────────────────────────────────────────
const router = require('express').Router();
const { verifyToken }      = require('../middleware/auth');
const { requireAuthority } = require('../middleware/authorityAuth');
const { trackingLimiter }  = require('../middleware/rateLimiter');
const trackingController   = require('../controllers/trackingController');

// Tourist uploads GPS logs (batch)
router.post('/batch',                  verifyToken, trackingLimiter, trackingController.batchUpload);
// Latest location for a tourist
router.get('/tourist/:touristId/latest', verifyToken, trackingController.getLatest);
// Full GPS history — authority only
router.get('/tourist/:touristId/history', verifyToken, requireAuthority, trackingController.getHistory);

module.exports = router;
