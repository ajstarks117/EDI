# 🏔️ TravelTrek Control Operations Centre

Welcome to the **TravelTrek Control Operations Centre**, a premium, mission-critical dashboard designed to oversee tourist safety, real-time telemetry tracking, active geofencing safeguards, and blockchain-verified identity syncs. Built to withstand high-altitude off-grid emergencies, the system relies on an innovative **Bluetooth Low Energy (BLE) Multi-Hop Relay Mesh Network** to route distress SOS alerts even in cellular deadzones.

---

## 🛠️ Tech Stack & Core Features

- **Frontend Core**: React 18, TypeScript, TailwindCSS (for high-fidelity premium glassmorphism dark theme)
- **State Management**: Zustand (securely guarded against SSR state leakages)
- **Virtualization**: `@tanstack/react-virtual` (enabling ultra-performance virtual list feeds for hundreds of active telemetry incidents)
- **Live Telemetry & Geofencing**: Google Maps API with drawing overlays, custom trails, and dynamic polygon tracking
- **Secure Blockchain Auth**: Blockchain QR Scanner Identity integration
- **Role-Based Access Control (RBAC)**: Gated admin features (Medical Records, Geofence configuration, Alert dispatch actions)

---

## 🚀 Quick Start & Local Development

### 1. Environment Variable Setup
Copy the template environment configuration file:
```bash
cp .env.example .env
```
Open `.env` and populate the necessary keys:
- `VITE_BACKEND_SOCKET_URL`: Backend websocket server endpoint (e.g. `http://localhost:4000`)
- `VITE_GOOGLE_MAPS_API_KEY`: Key to enable Google Maps tracking and drawing managers.

### 2. Dependency Installation
Install required packages using your package manager:
```bash
npm install
```

### 3. Start Development Server
Launch the development server:
```bash
npm run dev
```

---

## 🌐 Production Deployment Configuration

This dashboard is designed to be hosted on lightning-fast, static hosting platforms like **Vercel** or **Netlify**. Because it is a Single Page Application (SPA), server-side fallback configs are required to prevent `404 Not Found` errors when users refresh deep URLs like `/alerts` or `/settings`.

### ⚡ Netlify Deployment (`public/_redirects`)
We have configured a Netlify-native routing redirect file. It copies directly to the production build output:
```text
/*    /index.html   200
```

### 🔺 Vercel Deployment (`vercel.json`)
A custom Vercel configuration has been deployed in the root folder, enabling custom client rewrites for SPA routing:
```json
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

---

## 🛡️ Recommended Production Security Headers

To meet strict enterprise and defense auditing compliance, the following HTTP security headers are recommended and pre-configured within our `vercel.json` deployment script:

### 1. Content Security Policy (CSP)
Restricts which resources (JavaScript, CSS, Images, Connections) the browser is allowed to load. Prevents Cross-Site Scripting (XSS) and injection attacks.
```http
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://maps.googleapis.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data: https://maps.gstatic.com https://maps.googleapis.com https://i.pravatar.cc; connect-src 'self' ws: wss: http: https:; font-src 'self' https://fonts.gstatic.com; frame-src 'none'; object-src 'none';
```

### 2. HTTP Strict Transport Security (HSTS)
Enforces secure SSL/TLS connections for at least one year, including all subdomains.
```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

### 3. Frame & Content Sniffing Safeguards
- **`X-Frame-Options: DENY`**: Prevents clickjacking by blocking the dashboard from being embedded inside any `<iframe>`.
- **`X-Content-Type-Options: nosniff`**: Forces browsers to respect the declared Content-Type header to mitigate MIME-type sniffing.

### 4. Permissions Policy
Restricts device feature usage:
```http
Permissions-Policy: geolocation=(self), camera=(self), microphone=()
```
