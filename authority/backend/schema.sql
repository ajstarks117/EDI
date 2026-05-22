-- ============================================================
--  TravelSure — PostgreSQL 15 Schema
--  Run statements in the order shown.
--  Compatible with Railway / Render managed Postgres.
-- ============================================================

-- Enable pgcrypto for gen_random_uuid() (already available in PG 13+)
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- uncomment if needed

-- ── Tourists ─────────────────────────────────────────────────────────────────
CREATE TABLE tourists (
  id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  tourist_id         VARCHAR(20)  UNIQUE NOT NULL,
  phone              VARCHAR(20)  UNIQUE NOT NULL,
  full_name          VARCHAR(100) NOT NULL,
  nationality        VARCHAR(60),
  id_document_type   VARCHAR(20),
  id_number_hash     VARCHAR(64),
  blood_group        VARCHAR(5),
  medical_conditions TEXT,
  profile_photo_url  TEXT,
  region_code        VARCHAR(10),
  languages          TEXT[],
  is_active          BOOLEAN      DEFAULT true,
  created_at         TIMESTAMPTZ  DEFAULT NOW()
);

-- ── Emergency Contacts ───────────────────────────────────────────────────────
CREATE TABLE emergency_contacts (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tourist_id  UUID        REFERENCES tourists(id) ON DELETE CASCADE,
  name        VARCHAR(100),
  phone       VARCHAR(20),
  relation    VARCHAR(50)
);

-- ── Blockchain IDs ───────────────────────────────────────────────────────────
CREATE TABLE blockchain_ids (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tourist_id      UUID        REFERENCES tourists(id) ON DELETE CASCADE,
  tourist_ref_id  VARCHAR(20),
  identity_hash   VARCHAR(64),
  block_hash      VARCHAR(64),
  qr_data         TEXT,
  issued_at       TIMESTAMPTZ DEFAULT NOW(),
  valid_until     TIMESTAMPTZ
);

-- ── SOS Alerts ───────────────────────────────────────────────────────────────
CREATE TABLE sos_alerts (
  id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
  tourist_id          UUID            REFERENCES tourists(id),
  lat                 DOUBLE PRECISION NOT NULL,
  lng                 DOUBLE PRECISION NOT NULL,
  message             TEXT,
  source              VARCHAR(20),
  channel             VARCHAR(20),
  relay_tourist_id    UUID,
  blockchain_id_hash  VARCHAR(64),
  battery_percent     INT,
  status              VARCHAR(20)      DEFAULT 'active',
  priority            VARCHAR(10)      DEFAULT 'medium',
  authority_id        UUID,
  created_at          TIMESTAMPTZ      DEFAULT NOW()
);

-- ── GPS Logs ─────────────────────────────────────────────────────────────────
CREATE TABLE gps_logs (
  id          UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
  tourist_id  UUID             REFERENCES tourists(id) ON DELETE CASCADE,
  lat         DOUBLE PRECISION NOT NULL,
  lng         DOUBLE PRECISION NOT NULL,
  accuracy    DOUBLE PRECISION,
  captured_at TIMESTAMPTZ      NOT NULL,
  synced_at   TIMESTAMPTZ      DEFAULT NOW()
);

-- Index for fast location history queries
CREATE INDEX idx_gps_logs_tourist_captured ON gps_logs (tourist_id, captured_at DESC);

-- ── Geofence Zones ───────────────────────────────────────────────────────────
CREATE TABLE geofence_zones (
  id                       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name                     VARCHAR(100) NOT NULL,
  zone_type                VARCHAR(20)  NOT NULL,
  polygon_coordinates      JSONB,
  advisory_text            TEXT,
  is_active                BOOLEAN      DEFAULT true,
  created_by_authority_id  UUID,
  created_at               TIMESTAMPTZ  DEFAULT NOW()
);

-- ── Authorities ──────────────────────────────────────────────────────────────
CREATE TABLE authorities (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  badge_id       VARCHAR(30) UNIQUE NOT NULL,
  full_name      VARCHAR(100) NOT NULL,
  password_hash  VARCHAR(60),
  jurisdiction   VARCHAR(100),
  role           VARCHAR(30)  DEFAULT 'officer',
  created_at     TIMESTAMPTZ  DEFAULT NOW()
);

-- Add FK now that authorities exists
ALTER TABLE geofence_zones
  ADD CONSTRAINT fk_geofence_authority
  FOREIGN KEY (created_by_authority_id) REFERENCES authorities(id);

ALTER TABLE sos_alerts
  ADD CONSTRAINT fk_sos_authority
  FOREIGN KEY (authority_id) REFERENCES authorities(id);
