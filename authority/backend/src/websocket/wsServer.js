'use strict';

const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config/env');
const WS_EVENTS = require('./wsEvents');

/** @type {Server | null} */
let io = null;

// In-memory position cache
const positionCache = new Map();

const initWebSocketServer = (httpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: (origin, callback) => {
        callback(null, origin || '*');
      },
      methods: ['GET', 'POST'],
      credentials: true
    },
    pingInterval: 25000,
    pingTimeout: 10000,
  });

  // ── Auth middleware ──────────────────────────────────────────────────────
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;

    if (!token) {
      // For demo mode — allow unauthenticated connections to join authority room
      socket.user = { id: 'demo-operator', type: 'authority' };
      socket.clientType = 'authority';
      return next();
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || JWT_SECRET);
      socket.user = decoded;
      socket.clientType = socket.handshake.query?.type || decoded.type || 'tourist';
      return next();
    } catch (err) {
      // Allow through in demo mode instead of rejecting
      console.warn('[ws] JWT verification failed, allowing as demo authority:', err.message);
      socket.user = { id: `demo-${Date.now()}`, type: 'authority' };
      socket.clientType = 'authority';
      return next();
    }
  });

  // ── Connection handler ──────────────────────────────────────────────────
  io.on('connection', (socket) => {
    const type = socket.clientType || 'authority';

    // Join the appropriate room
    socket.join(type);
    console.log(`[ws] ${type} connected: ${socket.user?.id} (${socket.id})`);

    socket.emit('connected', { id: socket.user?.id, type });

    // ── Inbound message handlers ────────────────────────────────────────
    socket.on('ping', () => {
      socket.emit('pong');
    });

    socket.on('authority:join', () => {
      socket.join('authority');
      socket.emit('monitoring_confirmed');
    });

    socket.on('subscribe:region', (data) => {
      if (data?.region && socket.clientType === 'authority') {
        socket.region = data.region;
        socket.emit('subscribed', { region: data.region });
      }
    });

    socket.on('tourist:location', (data) => {
      if (data?.id && data?.lat != null && data?.lng != null) {
        positionCache.set(data.id, data);
        // Broadcast to all authority clients for live tracking
        io.to('authority').emit('tourist:location', data);
      }
    });

    socket.on('disconnect', () => {
      console.log(`[ws] ${type} disconnected: ${socket.user?.id} (${socket.id})`);
    });

    socket.on('error', (err) => console.error('[ws] Socket error:', err.message));
  });

  console.log('[ws] Socket.IO server initialised.');
  return io;
};

// ─── Broadcasters ─────────────────────────────────────────────────────────────

const broadcastToAuthorities = (event, data) => {
  if (!io) return;
  io.to('authority').emit(event, {
    ...data,
    ts: new Date().toISOString(),
  });
};

const sendToTourist = (touristId, event, data) => {
  if (!io) return;
  // Find sockets in 'tourist' room matching the touristId
  const touristRoom = io.sockets.adapter.rooms.get('tourist');
  if (touristRoom) {
    for (const socketId of touristRoom) {
      const s = io.sockets.sockets.get(socketId);
      if (s && s.user && s.user.id === touristId) {
        s.emit(event, { ...data, ts: new Date().toISOString() });
        break;
      }
    }
  }
};

const broadcastToAllTourists = (event, data) => {
  if (!io) return;
  io.to('tourist').emit(event, {
    ...data,
    ts: new Date().toISOString(),
  });
};

const getIO = () => io;

module.exports = {
  initWebSocketServer,
  broadcastToAuthorities,
  sendToTourist,
  broadcastToAllTourists,
  getIO,
  WS_EVENTS,
};
