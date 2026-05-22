# TravelSure Backend — Quick Start

## Prerequisites
- Node.js 20+
- PostgreSQL 15 (or use `docker-compose up -d` from repo root)
- A Firebase project with Admin SDK credentials

## Setup

```bash
# 1. Copy env file and fill in values
cp .env.example .env

# 2. Install dependencies
npm install

# 3. Create the database schema (with Docker running)
docker exec -i traveltrek-db psql -U traveltrek_admin -d traveltrek < schema.sql

# 4. Start the dev server
npm run dev
```

## API Base

| Prefix             | Description              |
|--------------------|--------------------------|
| `GET /health`      | Health check             |
| `POST /api/auth/*` | Authentication           |
| `GET/POST /api/tourists/*` | Tourist CRUD    |
| `POST /api/alerts/sos` | SOS trigger          |
| `POST /api/tracking/batch` | GPS batch upload |
| `GET/POST /api/geofence/zones` | Zone management |
| `POST /api/blockchain/verify` | Identity verify |
| `GET /api/dashboard/stats` | Dashboard stats  |
| `POST /api/ai/risk-score` | AI risk scoring   |

## WebSocket Events

Connect: `ws://localhost:3000`

| Event              | Direction | Description           |
|--------------------|-----------|-----------------------|
| `sos:new`          | Server→Client | New SOS alert     |
| `sos:update`       | Server→Client | SOS status change |
| `tourist:location` | Server→Client | Live GPS update   |
| `zone:update`      | Server→Client | Geofence change   |
| `alert:weather`    | Server→Client | Weather alert     |

Send `{ "action": "join", "room": "alerts" }` to subscribe to a room.

## Architecture

```
src/
├── index.js              Express server + WS init
├── config/               env, db pool, firebase, constants
├── middleware/           auth, authorityAuth, rateLimiter, validate, errorHandler
├── routes/               8 route files (501 stubs ready for implementation)
├── controllers/          one per route file
├── services/             business logic (sosService, blockchainService, …)
├── models/               raw SQL query functions (no ORM)
├── websocket/            wsServer.js (rooms, heartbeat) + wsEvents.js
└── utils/                hashUtils, geoUtils, responseUtils
```
