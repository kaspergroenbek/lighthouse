-- =============================================================================
-- 01_databases.sql — Create Lighthouse databases per environment and layer
-- =============================================================================
-- Purpose:  Provisions the three logical-layer databases for a given environment.
--           Databases follow the naming convention LIGHTHOUSE_{ENV}_{LAYER}.
--
-- Usage:    Run via deploy.sql which sets the env variable, or set it manually:
--           SET env = 'DEV';  (or STAGING, PROD)
--           Then execute this script.
--
-- Idempotency: Uses CREATE DATABASE IF NOT EXISTS — safe to re-run.
-- =============================================================================

-- Inherit env from deploy.sql, or set manually if running standalone
-- SET env = 'DEV';

-- RAW database — landing zone for all ingested source data
CREATE DATABASE IF NOT EXISTS IDENTIFIER('LIGHTHOUSE_' || $env || '_RAW')
    COMMENT = 'Lighthouse raw ingestion layer — landing zone for source system data';

-- ANALYTICS database — dbt transformation layers (staging, intermediate, marts, semantic)
CREATE DATABASE IF NOT EXISTS IDENTIFIER('LIGHTHOUSE_' || $env || '_ANALYTICS')
    COMMENT = 'Lighthouse analytics layer — dbt-managed staging, intermediate, marts, and semantic models';

-- SERVING database — near-real-time serving via Dynamic Tables
CREATE DATABASE IF NOT EXISTS IDENTIFIER('LIGHTHOUSE_' || $env || '_SERVING')
    COMMENT = 'Lighthouse serving layer — Dynamic Tables and real-time data products';
