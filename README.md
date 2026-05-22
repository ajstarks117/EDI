# TravelTrek: Smart Tourist Safety Monitoring & Incident Response System

TravelTrek (also referred to as TravelSure) is a multi-layered safety monitoring platform designed to protect tourists in remote or high-risk areas using Real-Time Tracking, Geo-Fencing, Blockchain Digital Identities, and a Fail-Safe Multi-Layer SOS communication system.

Developed under SIH Problem Statement ID 25002.

---

## 📂 Project Structure

This repository is organized as a modular multi-project workspace to support independent, concurrent development across the tourist and authority sub-systems:

```text
EDI/
├── tourist/                        # Tourist Mobile Application (Flutter)
├── authority/                      # Authority Ecosystem
│   ├── dashboard/                  # React Web Dashboard (Police/Rescue Control Room)
│   ├── backend/                    # Node.js + Express API & WebSocket Server
│   └── blockchain/                 # Hardhat Smart Contracts & Web3 Identity Layer
├── docker-compose.yml              # Local database & services orchestration
├── .gitignore                      # Workspace-wide git ignore rules
└── README.md                       # This developer documentation
```

---

## 🛠️ Technology Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Mobile App (Tourist)** | Flutter / Dart | Cross-platform app featuring offline tracking, SMS fallback, BLE mesh, and local Hive DB. |
| **Web App (Authority)** | React / TypeScript / Tailwind CSS | Operations dashboard with Leaflet/Mapbox maps, real-time alerts, and statistics. |
| **Backend API** | Node.js / Express / TypeScript | Shared API and WebSocket server for tracking, geofencing, and SOS dissemination. |
| **Blockchain** | Hardhat / Solidity | Mock Blockchain/Ethereum testnet storing tamper-proof Digital Tourist IDs. |
| **Database** | PostgreSQL / Firebase | Relational storage for user metadata, trip history, and active alerts. |

---

## 🚀 Getting Started

### Prerequisites
Make sure you have the following installed on your machine:
* [Docker & Docker Compose](https://www.docker.com/products/docker-desktop/)
* [Node.js (v18+)](https://nodejs.org/) & `npm`
* [Flutter SDK (v3.0+)](https://docs.flutter.dev/get-started/install)

---

### Step 1: Start Shared Services (Database & Local Blockchain)
Use Docker Compose from the root folder to start PostgreSQL and a local blockchain test node:
```bash
# From the EDI directory
docker-compose up -d
```

### Step 2: Running the Backend
1. Navigate to the backend directory:
   ```bash
   cd authority/backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up the local `.env` variables (see `authority/backend/.env.example`).
4. Run the development server:
   ```bash
   npm run dev
   ```

### Step 3: Running the Authority Dashboard
1. Navigate to the dashboard directory:
   ```bash
   cd authority/dashboard
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Run the development server:
   ```bash
   npm run dev
   ```

### Step 4: Running the Tourist Mobile App
1. Navigate to the app directory:
   ```bash
   cd tourist
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run on an emulator/device:
   ```bash
   flutter run
   ```

---

## 🔒 Security & Roles
* **Tourist Role**: Registered via KYC, tracks GPS coordinates locally when offline, broadcasts SOS alerts via available communication layers (WiFi, Mobile data, SMS fallback, Bluetooth, or Audio Siren).
* **Authority Role**: Accesses the React Web Dashboard to monitor active tourists, responds to critical alerts, establishes weather alerts, and configures geo-fenced high-risk areas.
