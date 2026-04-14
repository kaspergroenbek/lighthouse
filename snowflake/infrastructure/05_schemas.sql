-- =============================================================================
-- 05_schemas.sql — Create all schemas within Lighthouse databases
-- =============================================================================
-- Provisions schemas for each database layer. Schemas organize objects by
-- source system (RAW) or transformation stage (ANALYTICS).
--
-- Prerequisite: 01_databases.sql
-- Usage:        Run standalone or via deploy.sql. Change 'DEV' below as needed.
-- Idempotency:  Uses CREATE SCHEMA IF NOT EXISTS — safe to re-run.
-- =============================================================================

DECLARE
    env VARCHAR DEFAULT 'DEV';
    db_raw VARCHAR;
    db_analytics VARCHAR;
    db_serving VARCHAR;
BEGIN
    db_raw := 'LIGHTHOUSE_' || :env || '_RAW';
    db_analytics := 'LIGHTHOUSE_' || :env || '_ANALYTICS';
    db_serving := 'LIGHTHOUSE_' || :env || '_SERVING';

    -- RAW schemas — one per source system
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_raw || '.OLTP';
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_raw || '.CRM';
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_raw || '.IOT';
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_raw || '.PARTNER_FEEDS';
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_raw || '.KNOWLEDGE_BASE';

    -- ANALYTICS schemas — dbt transformation layers + governance
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_analytics || '.STAGING';
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_analytics || '.INTERMEDIATE';
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_analytics || '.MARTS';
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_analytics || '.SNAPSHOTS';
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_analytics || '.SEMANTIC';
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_analytics || '.TEST_RESULTS';
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_analytics || '.GOVERNANCE';

    -- SERVING schemas
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || :db_serving || '.REALTIME';

    RETURN 'Schemas created for environment: ' || :env;
END;
