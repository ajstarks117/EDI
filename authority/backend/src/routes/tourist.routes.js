'use strict';
// ─── Tourist Routes  /api/tourists/* ─────────────────────────────────────────
const router = require('express').Router();
const { verifyToken }      = require('../middleware/auth');
const touristController    = require('../controllers/touristController');
const blockchainController = require('../controllers/blockchainController');

router.get('/',    verifyToken, touristController.listTourists);
router.get('/:id', verifyToken, touristController.getTourist);
router.post('/',   verifyToken, touristController.createTourist);
router.put('/:id', verifyToken, touristController.updateTourist);
router.delete('/:id', verifyToken, touristController.deleteTourist);

// Emergency contacts sub-resource
router.get('/:id/contacts',  verifyToken, touristController.getContacts);
router.post('/:id/contacts', verifyToken, touristController.addContact);

// Blockchain identity — tourist fetches their own stored record
router.get('/:id/identity',  verifyToken, blockchainController.getTouristOwnIdentity);

module.exports = router;
