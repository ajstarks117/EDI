'use strict';
// ─── AI Routes  /api/ai/* ─────────────────────────────────────────────────────
const router = require('express').Router();
const { verifyToken }      = require('../middleware/auth');
const { requireAuthority } = require('../middleware/authorityAuth');
const aiController         = require('../controllers/aiController');

// LLM Chat / Emergency query
router.post('/chat',                   verifyToken, aiController.chat);
// Risk score prediction for a tourist / zone
router.post('/risk-score',             verifyToken, requireAuthority, aiController.predictRiskScore);
// Natural-language alert summarisation
router.post('/summarise-alert',        verifyToken, requireAuthority, aiController.summariseAlert);
// Route recommendation for safe travel
router.post('/safe-route',             verifyToken, aiController.getSafeRoute);

module.exports = router;
