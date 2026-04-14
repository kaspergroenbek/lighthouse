-- =============================================================================
-- 01_databases.sql — Create Lighthouse databases per environment and layer
-- =============================================================================
-- Purpose:  Provisions the three logical-layer databases for a given environment.
--           Databases follow the naming convention LIGHTHOUSE_{ENV}_{LAYER}.
--
-- Usage:    SET env = 'PROD';  (or DEV, STAGING)
--           Then execute this script.
--
-- Idempotency: Uses CREATE DATABASE IF NOT EXISTS — safe to re-run.
-- =============================================================================

-- Set the target environment (override before execution for DEV/STAGING)
SET env = 'PROD';

-- RAW database — landing zone for all ingested source data
CREATE DATABASE IF NOT EXISTS IDENTIFIER('LIGHTHOUSE_' || $env || '_RAW')
    COMMENT = 'Lighthouse raw ingestion layer — landing zone for source system data';

-- ANALYTICS database — dbt transformation layers (staging, intermediate, marts, semantic)
CREATE DATABASE IF NOT EXISTS IDENTIFIER('LIGHTHOUSE_' || $env || '_ANALYTICS')
    COMMENT = 'Lighthouse analytics layer — dbt-managed staging, intermediate, marts, and semantic models';

-- SERVING database — near-real-time serving via Dynamic Tables
CREATE DATABASE IF NOT EXISTS IDENTIFIER('LIGHTHOUSE_' || $env || '_SERVING')
    COMMENT = 'Lighthouse serving layer — Dynamic Tables and real-time data products';
