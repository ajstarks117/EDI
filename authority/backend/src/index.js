'use strict';

// ── Bootstrap ─────────────────────────────────────────────────────────────────
// env.js MUST be the first import — it loads .env and validates required vars.
const env = require('./config/env');

const http    = require('http');
const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const morgan  = require('morgan');

// Config — firebase is initialised as a side-effect (stubbed when SKIP_FIREBASE=true)
const { pool } = require('./config/db');
require('./config/firebase');

// Middleware
const { defaultLimiter }      = require('./middleware/rateLimiter');
const { errorHandler }        = require('./middleware/errorHandler');

// Routes
const authRoutes              = require('./routes/auth.routes');
const touristRoutes           = require('./routes/tourist.routes');
const sosRoutes               = require('./routes/sos.routes');
const trackingRoutes          = require('./routes/tracking.routes');
const geofenceRoutes          = require('./routes/geofence.routes');
const blockchainRoutes        = require('./routes/blockchain.routes');
const dashboardRoutes         = require('./routes/dashboard.routes');
const aiRoutes                = require('./routes/ai.routes');

// WebSocket
const { initWebSocketServer } = require('./websocket/wsServer');

// Background services
const { startEscalationService } = require('./services/escalationService');

// ── Express App ───────────────────────────────────────────────────────────────
const app = express();

// ── Global Middleware ─────────────────────────────────────────────────────────
app.use(helmet());

app.use(cors({
  origin: env.NODE_ENV === 'production'
    ? (process.env.ALLOWED_ORIGINS || '').split(',').map((o) => o.trim())
    : '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(morgan(env.NODE_ENV === 'production' ? 'combined' : 'dev'));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(defaultLimiter);

// ── Health Check ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ── API Routes ────────────────────────────────────────────────────────────────
app.use('/api/auth',       authRoutes);
app.use('/api/tourists',   touristRoutes);
app.use('/api/alerts',     sosRoutes);
app.use('/api/tracking',   trackingRoutes);
app.use('/api/geofence',   geofenceRoutes);
app.use('/api/blockchain', blockchainRoutes);
app.use('/api/dashboard',  dashboardRoutes);
app.use('/api/ai',         aiRoutes);

// ── 404 Catch-all ─────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ success: false, message: 'Route not found.' });
});

// ── Global Error Handler (must be last middleware) ────────────────────────────
app.use(errorHandler);

// ── HTTP + WebSocket Server ───────────────────────────────────────────────────
const httpServer = http.createServer(app);
initWebSocketServer(httpServer);

// ── Startup ───────────────────────────────────────────────────────────────────
const start = async () => {
  // Start listening immediately — health check must be reachable even
  // while DB is still warming up (especially on Railway / Render cold starts).
  await new Promise((resolve) => {
    httpServer.listen(env.PORT, () => {
      console.log(`[server] TravelSure API running on port ${env.PORT} (${env.NODE_ENV})`);
      resolve();
    });
  });

  // Start auto-escalation (setInterval every 60s)
  escalationTimer = startEscalationService();

  // Verify DB connectivity in the background — warn but don't crash.
  pool.query('SELECT 1')
    .then(() => console.log('[db] PostgreSQL connection pool ready.'))
    .catch((err) => console.warn('[db] PostgreSQL not reachable yet:', err.message));
};

// ── Graceful Shutdown ─────────────────────────────────────────────────────────
let escalationTimer = null;

const shutdown = (signal) => {
  console.log(`\n[server] ${signal} received — shutting down gracefully.`);
  if (escalationTimer) clearInterval(escalationTimer);
  httpServer.close(async () => {
    await pool.end().catch(() => {});
    console.log('[server] HTTP server and DB pool closed. Goodbye.');
    process.exit(0);
  });
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));

start();

module.exports = app; // for testing
