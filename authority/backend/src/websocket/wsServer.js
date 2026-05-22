'use strict';

const { WebSocketServer, WebSocket } = require('ws');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config/env');
const WS_EVENTS = require('./wsEvents');

/** @type {WebSocketServer | null} */
let wss = null;

const authorityClients = new Map();
const touristClients = new Map();

// In-memory position cache
const positionCache = new Map();

const initWebSocketServer = (httpServer) => {
  wss = new WebSocketServer({ server: httpServer });

  wss.on('connection', (ws, req) => {
    const ip = req.socket.remoteAddress;
    ws.isAlive = true;
    ws.missedHeartbeats = 0;

    try {
      // req.url may not have full host, dummy host used for parsing
      const url = new URL(req.url, `http://localhost`);
      const type = url.searchParams.get('type');
      const token = url.searchParams.get('token');

      if (!token) {
        ws.close(4001, 'Missing token');
        return;
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET || JWT_SECRET);
      ws.user = decoded;
      ws.clientType = type || decoded.type;

      if (ws.clientType === 'authority') {
        authorityClients.set(decoded.id, ws);
      } else {
        touristClients.set(decoded.id, ws);
      }

      ws.send(JSON.stringify({ event: 'connected', data: { id: decoded.id, type: ws.clientType } }));
    } catch (err) {
      console.error('[ws] Auth error:', err.message);
      ws.close(4001, 'Invalid token');
      return;
    }

    console.log(`[ws] ${ws.clientType} connected from ${ip}`);

    ws.on('pong', () => { 
      ws.isAlive = true; 
      ws.missedHeartbeats = 0;
    });

    ws.on('message', (raw) => {
      try {
        const msg = JSON.parse(raw);
        handleMessage(ws, msg);
      } catch (err) {
        ws.send(JSON.stringify({ event: 'error', message: 'Invalid JSON.' }));
      }
    });

    ws.on('close', () => {
      if (ws.clientType === 'authority') {
        authorityClients.delete(ws.user.id);
      } else {
        touristClients.delete(ws.user.id);
      }
      console.log(`[ws] ${ws.clientType} disconnected (${ip})`);
    });

    ws.on('error', (err) => console.error('[ws] Socket error:', err.message));
  });

  // Heartbeat — every 30s
  const heartbeat = setInterval(() => {
    const now = Date.now();
    wss.clients.forEach((ws) => {
      if (ws.isAlive === false) {
        ws.missedHeartbeats++;
        if (ws.missedHeartbeats >= 2) {
          if (ws.clientType === 'authority') authorityClients.delete(ws.user.id);
          else touristClients.delete(ws.user.id);
          return ws.terminate();
        }
      }
      ws.isAlive = false;
      ws.ping();
      ws.send(JSON.stringify({ event: 'heartbeat', ts: now }));
    });
  }, 30_000);

  wss.on('close', () => clearInterval(heartbeat));

  console.log('[ws] WebSocket server initialised.');
  return wss;
};

// ─── Broadcasters ─────────────────────────────────────────────────────────────

const broadcastToAuthorities = (event, data) => {
  const message = JSON.stringify({ event, data, ts: new Date().toISOString() });
  authorityClients.forEach((ws) => {
    if (ws.readyState === WebSocket.OPEN) ws.send(message);
  });
};

const sendToTourist = (touristId, event, data) => {
  const ws = touristClients.get(touristId);
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ event, data, ts: new Date().toISOString() }));
  }
};

const broadcastToAllTourists = (event, data) => {
  const message = JSON.stringify({ event, data, ts: new Date().toISOString() });
  touristClients.forEach((ws) => {
    if (ws.readyState === WebSocket.OPEN) ws.send(message);
  });
};

// ─── Inbound Message Dispatcher ───────────────────────────────────────────────

const handleMessage = (ws, msg) => {
  const { event, data } = msg;
  switch (event) {
    case 'ping':
      ws.send(JSON.stringify({ event: 'pong' }));
      break;
    case 'authority:join':
      ws.send(JSON.stringify({ event: 'monitoring_confirmed' }));
      break;
    case 'tourist:location':
      if (data && ws.user) {
        positionCache.set(ws.user.id, data);
      }
      break;
    default:
      break;
  }
};

module.exports = {
  initWebSocketServer,
  broadcastToAuthorities,
  sendToTourist,
  broadcastToAllTourists,
  WS_EVENTS,
};
