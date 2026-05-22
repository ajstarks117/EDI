'use strict';
// ─── Dashboard Routes  /api/dashboard/* ──────────────────────────────────────
const router = require('express').Router();
const { verifyToken }      = require('../middleware/auth');
const { requireAuthority } = require('../middleware/authorityAuth');
const dashboardController  = require('../controllers/dashboardController');

router.get('/stats',                   verifyToken, requireAuthority, dashboardController.getStats);
router.get('/analytics',               verifyToken, requireAuthority, dashboardController.getAnalytics);
router.get('/active-alerts',           verifyToken, requireAuthority, dashboardController.getActiveAlerts);
router.get('/tourist-density',         verifyToken, requireAuthority, dashboardController.getTouristDensity);

module.exports = router;
