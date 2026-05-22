import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*', // Customize this for production
    methods: ['GET', 'POST']
  }
});

// Middlewares
app.use(cors());
app.use(express.json());

// Port
const PORT = process.env.PORT || 5000;

// PostgreSQL Pool Initialization (Mocked error handling if not running in Docker)
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://traveltrek_admin:traveltrek_secure_password@localhost:5432/traveltrek'
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client', err);
});

// REST API Base Route
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'TravelTrek Core API', timestamp: new Date() });
});

// Mock Storage for memory fail-safes
const activeSOS: any[] = [];

// REST Routes: Trigger Emergency SOS (HTTP Fallback)
app.post('/api/emergency/sos', (req, res) => {
  const { touristId, touristName, latitude, longitude, type, description } = req.body;
  
  const alert = {
    id: `AL-${Math.floor(1000 + Math.random() * 9000)}`,
    type: type || 'SOS Triggered',
    touristName,
    touristId,
    gps: `${latitude}, ${longitude}`,
    time: 'Just now',
    priority: 'CRITICAL',
    status: 'NEW',
    description: description || 'Panic button activated by tourist.',
    emergencyContact: 'Not specified'
  };

  activeSOS.push(alert);

  // Broadcast to all connected web dashboard sessions via WebSockets
  io.emit('new_emergency_alert', alert);

  res.status(201).json({ success: true, alertId: alert.id, message: 'Emergency SOS Broadcasted' });
});

// REST Routes: Get Active Emergencies
app.get('/api/emergency/active', (req, res) => {
  res.status(200).json({ success: true, data: activeSOS });
});

// WebSockets: Real-time Location Streams & Instant SOS Propagation
io.on('connection', (socket) => {
  console.log(`Client connected: ${socket.id}`);

  // Tourist sends live location update
  socket.on('tourist_location_update', async (data) => {
    const { touristId, latitude, longitude } = data;
    console.log(`Location update from ${touristId}: [${latitude}, ${longitude}]`);
    
    // Broadcast back to authority dashboard maps
    io.emit('authority_location_broadcast', {
      touristId,
      latitude,
      longitude,
      timestamp: new Date()
    });

    // Optionally: Store to Postgres database in production
    /*
    try {
      await pool.query(
        'INSERT INTO tourist_locations (tourist_id, latitude, longitude, timestamp) VALUES ($1, $2, $3, $4)',
        [touristId, latitude, longitude, new Date()]
      );
    } catch (err) {
      console.error('Error saving location trace:', err);
    }
    */
  });

  // Tourist triggers instant WebSocket SOS
  socket.on('tourist_sos_trigger', (data) => {
    const { touristId, touristName, latitude, longitude, type } = data;
    
    const alert = {
      id: `AL-${Math.floor(1000 + Math.random() * 9000)}`,
      type: type || 'SOS Triggered',
      touristName,
      touristId,
      gps: `${latitude}, ${longitude}`,
      time: 'Just now',
      priority: 'CRITICAL',
      status: 'NEW',
      description: 'Panic button activated by tourist.',
      emergencyContact: 'Not specified'
    };

    activeSOS.push(alert);
    
    // Propagate instantly to authority control screens
    io.emit('new_emergency_alert', alert);
  });

  socket.on('disconnect', () => {
    console.log(`Client disconnected: ${socket.id}`);
  });
});

// Start Server
server.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(`TravelTrek Backend Service running on port ${PORT}`);
  console.log(`API URL: http://localhost:${PORT}/api/health`);
  console.log(`WebSocket Server listening for connections...`);
  console.log(`====================================================`);
});
