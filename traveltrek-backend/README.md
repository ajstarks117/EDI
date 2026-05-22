# TravelTrek Backend Service

This is the central Express.js and TypeScript server. It acts as the API and WebSockets server for the TravelTrek project, routing real-time GPS locations and emergency broadcasts between the mobile application and the web dashboard.

## 📂 Project Structure

```text
src/
├── index.ts                # Server initialization, routing, and WebSockets configuration
├── routes/                 # Express router subfolders
│   ├── auth.ts             # JWT-based admin and user KYC login
│   ├── tracking.ts         # Coordinates archiving endpoint
│   └── emergency.ts        # Emergency triggers (SMS & Webhook dispatcher)
└── database/               # PostgreSQL client configs
```

## 🛠️ API Routes

### 1. Health Checks
* `GET /api/health`: Services validation

### 2. Emergency Triggers (HTTP Fallback)
* `POST /api/emergency/sos`: Trigger a new emergency alert.
  * Request Body:
    ```json
    {
      "touristId": "IND-643269-HO5",
      "touristName": "Arjun Kumar",
      "latitude": 18.9696,
      "longitude": 72.8193,
      "type": "Panic Button Activated",
      "description": "Tourist feels followed near platform 4."
    }
    ```
* `GET /api/emergency/active`: List current unresolved alerts.

---

## 📡 WebSocket API Protocol

### 1. Client to Server Events
* `tourist_location_update`: Emitted by the Flutter app to publish the user's latest latitude and longitude coordinate traces.
  * Payloads: `{ touristId: string, latitude: double, longitude: double }`
* `tourist_sos_trigger`: Emitted by the Flutter app when the Emergency SOS is activated.
  * Payloads: `{ touristId: string, touristName: string, latitude: double, longitude: double, type: string }`

### 2. Server to Client Events
* `authority_location_broadcast`: Forwarded in real-time to active authority web maps.
* `new_emergency_alert`: Forwarded to all active dashboards to display alert popups and trigger audio queues.

---

## 🚀 Local Run Guide

1. Create a local environment variables file:
   ```bash
   cp .env.example .env
   ```
2. Install package requirements:
   ```bash
   npm install
   ```
3. Start the hot-reloading dev server:
   ```bash
   npm run dev
   ```
4. Build for deployment:
   ```bash
   npm run build
   ```
