'use strict';

const admin = require('firebase-admin');

try {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!serviceAccountJson) {
    console.warn('Warning: FIREBASE_SERVICE_ACCOUNT_JSON is missing from environment variables. Firebase Admin SDK not initialised.');
  } else {
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(JSON.parse(serviceAccountJson))
      });
      console.log('[firebase] Admin SDK successfully initialised.');
    }
  }
} catch (err) {
  console.warn('Warning: Failed to initialize Firebase Admin SDK:', err.message);
}

module.exports = admin;
