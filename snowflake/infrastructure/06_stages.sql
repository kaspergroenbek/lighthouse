-- =============================================================================
-- 06_stages.sql — Create internal stages per source system
-- =============================================================================
-- Purpose:  Provisions internal stages in each RAW schema for loading
--           synthetic seed data via PUT + COPY INTO.
--
-- Prerequisite: 01_databases.sql, 05_schemas.sql
--
-- Stages:
--   @RAW.OLTP.oltp_stage            — CDC simulation CSVs
--   @RAW.CRM.crm_stage              — SaaS connector simulation CSVs
--   @RAW.IOT.iot_stage              — JSON telemetry event files
--   @RAW.PARTNER_FEEDS.partner_stage — CSV/Parquet partner files
--   @RAW.KNOWLEDGE_BASE.kb_stage    — Markdown/text documents
--
-- Idempotency: Uses CREATE OR REPLACE STAGE — safe to re-run.
-- =============================================================================

-- Inherit env from deploy.sql, or set manually if running standalone
-- SET env = 'DEV';

-- OLTP source stage — CDC simulation seed CSVs
EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE LIGHTHOUSE_' || $env || '_RAW.OLTP.oltp_stage
    COMMENT = ''Internal stage for OLTP CDC seed data files''';

-- CRM source stage — SaaS connector simulation seed CSVs
EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE LIGHTHOUSE_' || $env || '_RAW.CRM.crm_stage
    COMMENT = ''Internal stage for CRM SaaS connector seed data files''';

-- IoT source stage — JSON telemetry event files
EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE LIGHTHOUSE_' || $env || '_RAW.IOT.iot_stage
    COMMENT = ''Internal stage for IoT telemetry JSON event files''';

-- Partner Feeds source stage — CSV/Parquet partner files
EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE LIGHTHOUSE_' || $env || '_RAW.PARTNER_FEEDS.partner_stage
    COMMENT = ''Internal stage for partner feed CSV and Parquet files''';

-- Knowledge Base source stage — Markdown/text documents
EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE LIGHTHOUSE_' || $env || '_RAW.KNOWLEDGE_BASE.kb_stage
    COMMENT = ''Internal stage for knowledge base document files''';
