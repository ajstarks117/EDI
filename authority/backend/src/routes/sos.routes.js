'use strict';
// ─── SOS / Alert Routes  /api/alerts/* ───────────────────────────────────────
const router = require('express').Router();
const { verifyToken }       = require('../middleware/auth');
const { verifyAuthority }   = require('../middleware/authorityAuth');
const { sosLimiter }        = require('../middleware/rateLimiter');
const { auditLog }          = require('../middleware/auditLog');
const sosController         = require('../controllers/sosController');

// ── Tourist-facing ────────────────────────────────────────────────────────────

// Rate-limited SOS trigger — tourist JWT required
router.post('/sos',
  verifyToken,
  sosLimiter,
  auditLog('TRIGGER_SOS'),
  sosController.triggerSOS
);

// ── Authority-facing ──────────────────────────────────────────────────────────

// Paginated alert list with optional ?status=&priority= filters
router.get('/',
  verifyAuthority,
  sosController.listAlerts
);

// Broadcast a weather alert to all WebSocket clients
router.post('/weather',
  verifyAuthority,
  sosController.weatherAlert
);

// Update alert status: acknowledged | resolved
router.patch('/:id/status',
  verifyAuthority,
  auditLog('UPDATE_SOS_STATUS'),
  sosController.updateStatus
);

// Assign an authority officer to an alert
router.post('/:id/assign',
  verifyAuthority,
  sosController.assignAuthority
);

// ── Shared (any valid token) ──────────────────────────────────────────────────

// Get single alert detail
router.get('/:id',
  verifyToken,
  sosController.getAlert
);

module.exports = router;
