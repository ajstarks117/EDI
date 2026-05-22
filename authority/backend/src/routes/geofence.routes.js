'use strict';
// ─── Geofence Routes  /api/geofence/* ────────────────────────────────────────
const router = require('express').Router();
const { verifyToken }      = require('../middleware/auth');
const { requireAuthority } = require('../middleware/authorityAuth');
const geofenceController   = require('../controllers/geofenceController');

router.get('/zones',                   verifyToken, geofenceController.listZones);
router.get('/zones/:id',               verifyToken, geofenceController.getZone);
router.post('/zones',                  verifyToken, requireAuthority, geofenceController.createZone);
router.put('/zones/:id',               verifyToken, requireAuthority, geofenceController.updateZone);
router.delete('/zones/:id',            verifyToken, requireAuthority, geofenceController.deleteZone);

// Check whether a given lat/lng is inside any active zone
router.post('/check',                  verifyToken, geofenceController.checkPoint);

module.exports = router;
