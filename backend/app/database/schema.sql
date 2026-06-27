-- ============================================================
-- UBICASAFE RAG Database Schema — PostgreSQL + pgvector
-- ============================================================

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Reports (denuncias de incidentes) ────────────────────────
CREATE TABLE IF NOT EXISTS reports (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type     VARCHAR(50)   NOT NULL,
    location_text   VARCHAR(500)  NOT NULL,
    latitude        DOUBLE PRECISION,
    longitude       DOUBLE PRECISION,
    incident_date   TIMESTAMP     NOT NULL,
    violence_level  VARCHAR(20)   NOT NULL,
    had_injuries    BOOLEAN       DEFAULT FALSE,
    had_weapons     BOOLEAN       DEFAULT FALSE,
    weapon_type     VARCHAR(50),
    description     TEXT          NOT NULL,
    device_brand    VARCHAR(100),
    device_model    VARCHAR(200),
    device_condition VARCHAR(100),
    device_color    VARCHAR(50),
    embedding       VECTOR(768),
    created_at      TIMESTAMP     DEFAULT NOW(),
    updated_at      TIMESTAMP     DEFAULT NOW()
);

-- ── Risk Zones (zonas de riesgo) ─────────────────────────────
CREATE TABLE IF NOT EXISTS risk_zones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(200)    NOT NULL,
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    radius_meters   DOUBLE PRECISION NOT NULL,
    risk_level      VARCHAR(20)     NOT NULL,
    description     TEXT            NOT NULL,
    report_count    INTEGER         DEFAULT 0,
    last_incident_at TIMESTAMP,
    embedding       VECTOR(768),
    created_at      TIMESTAMP       DEFAULT NOW()
);

-- ── Vector Indexes (ivfflat — good up to ~1M rows) ──────────
-- NOTE: ivfflat requires data to exist before building.
-- Run these AFTER seeding initial data.
-- CREATE INDEX idx_reports_embedding ON reports
--     USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
-- CREATE INDEX idx_zones_embedding ON risk_zones
--     USING ivfflat (embedding vector_cosine_ops) WITH (lists = 20);

-- ── Conventional Indexes ─────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_reports_date      ON reports (incident_date DESC);
CREATE INDEX IF NOT EXISTS idx_reports_type      ON reports (report_type);
CREATE INDEX IF NOT EXISTS idx_reports_violence  ON reports (violence_level);
CREATE INDEX IF NOT EXISTS idx_reports_location  ON reports (latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_zones_risk_level  ON risk_zones (risk_level);
