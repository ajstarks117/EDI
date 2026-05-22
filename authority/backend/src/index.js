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
const { generalLimiter, authLimiter, trackingLimiter, sosLimiter, aiLimiter } = require('./middleware/rateLimiter');
const { sanitize }            = require('./middleware/sanitize');
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

app.use(cors({ origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*' }));

app.use(morgan(env.NODE_ENV === 'production' ? 'combined' : 'dev'));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(sanitize);

// ── Health Check ──────────────────────────────────────────────────────────────
app.get('/health', async (_req, res) => {
  let dbStatus = 'disconnected';
  try {
    const client = await pool.connect();
    // Wrap in Promise.race for 3s timeout
    await Promise.race([
      client.query('SELECT 1'),
      new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 3000))
    ]);
    client.release();
    dbStatus = 'connected';
  } catch (err) {
    dbStatus = 'error';
  }

  let active_sos_alerts = 0;
  try {
    if (dbStatus === 'connected') {
      const sosRes = await pool.query(`SELECT COUNT(*) as count FROM sos_alerts WHERE status = 'active'`);
      active_sos_alerts = parseInt(sosRes.rows[0].count, 10);
    }
  } catch (err) {}

  // Fetch WS Rooms directly from server if possible, or we can just mock the sizes based on the Maps in wsServer
  // We need to require the maps from wsServer, but since we can't easily export them dynamically without breaking scope,
  // we'll leave them as unknown or calculate from clients.
  
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    db: dbStatus,
    ws_connections: {
      authorities: 'unknown (see wsServer Maps)',
      tourists: 'unknown (see wsServer Maps)'
    },
    active_sos_alerts,
    uptime_seconds: process.uptime(),
    version: '1.0.0'
  });
});

// ── Rate Limiters ─────────────────────────────────────────────────────────────
app.use('/api/auth', authLimiter);
app.use('/api/alerts/sos', sosLimiter);
app.use('/api/sos', sosLimiter);
app.use('/api/ai', aiLimiter);
app.use('/api', generalLimiter);

// ── Demo-Bypass SOS Route (No JWT — for SIH demo) ─────────────────────────────
// The tourist app sends SOS here without a JWT token. We accept the payload,
// persist if DB is available, and broadcast to the authority dashboard via Socket.IO.
const { broadcastToAuthorities, getIO } = require('./websocket/wsServer');
const WS_EVENTS = require('./websocket/wsEvents');
const { v4: uuidv4 } = require('uuid');

app.post('/api/sos', async (req, res) => {
  try {
    const { lat, lng, message, source, blockchain_id_hash, battery_percent,
            connectivity, emergency_contacts, channel } = req.body;

    // Derive priority: manual trigger or low battery = P0, non-internet = P2, else P3
    let priority = 'P3';
    if (source === 'manual' || (battery_percent != null && battery_percent < 15)) {
      priority = 'P0';
    } else if (channel !== 'internet') {
      priority = 'P2';
    }

    const alertId = uuidv4();
    const alertMessage = message || `SOS triggered via ${source || 'unknown'}`;

    // Try to persist in DB
    let dbInserted = false;
    try {
      // Look up tourist by blockchain_id_hash or create a demo record
      let touristDbId = null;
      if (blockchain_id_hash) {
        const { rows } = await pool.query(
          `SELECT id FROM tourists WHERE identity_hash = $1 LIMIT 1`,
          [blockchain_id_hash]
        );
        if (rows.length > 0) touristDbId = rows[0].id;
      }

      if (!touristDbId) {
        // Try to find any tourist for demo
        const { rows } = await pool.query(`SELECT id FROM tourists LIMIT 1`);
        touristDbId = rows.length > 0 ? rows[0].id : null;
      }

      if (touristDbId) {
        const dbPriority = priority === 'P0' ? 'critical' : priority === 'P2' ? 'medium' : 'low';
        await pool.query(
          `INSERT INTO sos_alerts (id, tourist_id, lat, lng, source, channel, battery_percent, priority, status)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'active')`,
          [alertId, touristDbId, lat || 0, lng || 0, source || 'manual',
           channel || 'internet', battery_percent || 100, dbPriority]
        );
        dbInserted = true;
      }
    } catch (dbErr) {
      console.warn('[demo-sos] DB insert failed (non-fatal):', dbErr.message);
    }

    // Broadcast to all authority dashboard sockets — this is the critical piece
    broadcastToAuthorities('alert:new', {
      id:         alertId,
      priority:   priority,
      message:    alertMessage,
      touristId:  blockchain_id_hash || 'demo-tourist',
      lat:        lat || 0,
      lng:        lng || 0,
      status:     'new',
      source:     source || 'manual',
      channel:    channel || 'internet',
      battery_percent: battery_percent,
      connectivity: connectivity,
      emergency_contacts: emergency_contacts,
    });

    console.log(`[demo-sos] SOS broadcast — ${priority} — lat:${lat} lng:${lng} (db:${dbInserted})`);

    return res.status(201).json({ id: alertId });
  } catch (err) {
    console.error('[demo-sos] Error:', err);
    return res.status(500).json({ error: 'SOS processing failed' });
  }
});

// ── Demo Location Sync (Background tracking from tourist app) ─────────────────
app.post('/api/emergency/sos', async (req, res) => {
  try {
    const { touristId, touristName, latitude, longitude, type, description } = req.body;

    // Broadcast as tourist:location event to authority dashboards
    const io = getIO();
    if (io) {
      io.to('authority').emit('tourist:location', {
        id: touristId || 'unknown',
        name: touristName || 'Tourist',
        lat: latitude || 0,
        lng: longitude || 0,
        status: type === 'CRITICAL EMERGENCY SOS' ? 'critical' : 'safe',
        ts: new Date().toISOString(),
      });
    }

    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('[demo-location] Error:', err);
    return res.status(500).json({ error: 'Location sync failed' });
  }
});

// ── Geofence Zones — Tourist App Alias ────────────────────────────────────────
// Tourist app calls GET /geofence/zones (without /api prefix)
app.get('/geofence/zones', (req, res, next) => {
  req.url = '/zones';
  geofenceRoutes(req, res, next);
});

// ── AI Chat Proxy — Tourist App Alias ─────────────────────────────────────────
// Tourist app calls POST /ai/chat (without /api prefix)
app.post('/ai/chat', (req, res, next) => {
  req.url = '/chat';
  aiRoutes(req, res, next);
});

// ── Auth Register — Tourist App Alias ─────────────────────────────────────────
// Tourist app calls POST /auth/register (without /api prefix)
app.post('/auth/register', (req, res, next) => {
  req.url = '/register';
  authRoutes(req, res, next);
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
    const PORT = env.PORT || 3001;
    httpServer.listen(PORT, '0.0.0.0', () => {
      console.log(`[server] TravelSure API running on port ${PORT} (${env.NODE_ENV})`);
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
