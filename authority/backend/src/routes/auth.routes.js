'use strict';
// ─── Auth Routes  /api/auth/* ─────────────────────────────────────────────────
const router = require('express').Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { authLimiter } = require('../middleware/rateLimiter');
const authController = require('../controllers/authController');
const { validateRegistration } = require('../middleware/registrationValidator');
const { auditLog } = require('../middleware/auditLog');

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, file.fieldname + '-' + uniqueSuffix + ext);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
});

router.post('/register',              authLimiter, upload.single('profile_photo'), validateRegistration, auditLog('REGISTER_TOURIST'), authController.register);
router.post('/login',                 authLimiter, authController.login);
router.post('/authority/login',        authLimiter, authController.authorityLogin);
router.post('/refresh-token',         authLimiter, authController.refreshToken);
router.post('/verify-firebase-token', authLimiter, authController.verifyFirebaseToken);
router.post('/logout',                             authController.logout);

module.exports = router;
