-- =============================================================================
-- 05_schemas.sql — Create all schemas within Lighthouse databases
-- =============================================================================
-- Purpose:  Provisions schemas for each database layer. Schemas organize
--           objects by source system (RAW) or transformation stage (ANALYTICS).
--
-- Prerequisite: 01_databases.sql
--
-- Schema layout:
--   RAW       → OLTP, CRM, IOT, PARTNER_FEEDS, KNOWLEDGE_BASE
--   ANALYTICS → STAGING, INTERMEDIATE, MARTS, SNAPSHOTS, SEMANTIC,
--               TEST_RESULTS, GOVERNANCE
--   SERVING   → REALTIME
--
-- Idempotency: Uses CREATE SCHEMA IF NOT EXISTS — safe to re-run.
-- =============================================================================

-- Inherit env from deploy.sql, or set manually if running standalone
-- SET env = 'DEV';

-- ─────────────────────────────────────────────────────────────────────────────
-- RAW database schemas — one per source system
-- ─────────────────────────────────────────────────────────────────────────────

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_RAW.OLTP
    COMMENT = ''CDC raw tables from NordHjem PostgreSQL OLTP system''';

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_RAW.CRM
    COMMENT = ''SaaS connector raw tables from NordHjem CRM platform''';

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_RAW.IOT
    COMMENT = ''Streaming telemetry raw tables from smart home devices''';

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_RAW.PARTNER_FEEDS
    COMMENT = ''Batch file raw tables from energy grid operators and partners''';

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_RAW.KNOWLEDGE_BASE
    COMMENT = ''Document tracking, extracted text, and chunked content''';

-- ─────────────────────────────────────────────────────────────────────────────
-- ANALYTICS database schemas — dbt transformation layers + governance
-- ─────────────────────────────────────────────────────────────────────────────

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.STAGING
    COMMENT = ''dbt staging models — source-conforming standardization''';

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.INTERMEDIATE
    COMMENT = ''dbt intermediate models — business logic and cross-source joins''';

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.MARTS
    COMMENT = ''dbt marts — Kimball star schema dimensions and facts''';

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.SNAPSHOTS
    COMMENT = ''dbt SCD Type 2 snapshots''';

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.SEMANTIC
    COMMENT = ''Semantic views for Cortex Analyst natural-language querying''';

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.TEST_RESULTS
    COMMENT = ''dbt test result history for observability and alerting''';

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.GOVERNANCE
    COMMENT = ''Governance objects — classification tags, masking policies, row access policies''';

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVING database schemas — near-real-time data products
-- ─────────────────────────────────────────────────────────────────────────────

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_SERVING.REALTIME
    COMMENT = ''Dynamic Tables for near-real-time serving''';
