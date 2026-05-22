# TravelTrek Authority Control Dashboard

This is the React-based operations dashboard designed for police stations, control rooms, rescue teams, and tourism administration authorities. It enables real-time geo-location tracking of tourists, SOS alert triage, weather warning broadcast, and active geo-fencing configuration.

## 📁 Project Structure

The project has been structured cleanly for modular development:

```text
src/
├── main.tsx                # App entry point
├── App.tsx                 # Core UI Shell, interactive state managers, and tab routing
├── index.css               # Styling declarations, theme configs, scrollbars, and pulses
├── components/             # Reusable UI controls
│   ├── AlertCard.tsx       # Dispatch incident logger card
│   ├── StatCard.tsx        # High-contrast metric panel
│   └── MapView.tsx         # Leaflet/Mapbox WebGL component wrapper
├── pages/                  # Top-level routes / panels
│   ├── Overview.tsx        # Central control panel
│   ├── TrackingMap.tsx     # Map display panel
│   ├── IncidentLog.tsx     # SOS triage logger
│   └── Configs.tsx         # Geo-fencing and broadcast tools
```

## 🛠️ Features Included

1. **Dashboard Triage**: Real-time mock notifications matching the SIH-25002 requirements document.
2. **Duty Status Control**: Simulate active/inactive officer shifts.
3. **Interactive Actions**: Initiate emergency call redirects and dispatch or resolve alerts on-chain.
4. **Geofencing & Alerts**: Interface for configuring safety borders and broadcasting push/SMS advisories to nearby travelers.

## 🚀 Dev Environment Setup

1. Install local dependencies:
   ```bash
   npm install
   ```
2. Start the Vite development server:
   ```bash
   npm run dev
   ```
3. Open [http://localhost:3000](http://localhost:3000) in your browser.
4. Compile/Build check:
   ```bash
   npm run build
   ```
