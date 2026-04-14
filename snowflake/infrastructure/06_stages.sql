-- =============================================================================
-- 06_stages.sql — Create internal stages per source system
-- =============================================================================
-- Provisions internal stages in each RAW schema for loading synthetic seed
-- data via PUT + COPY INTO.
--
-- Prerequisite: 01_databases.sql, 05_schemas.sql
-- Usage:        Run standalone or via deploy.sql. Change 'DEV' below as needed.
-- Idempotency:  Uses CREATE OR REPLACE STAGE — safe to re-run.
-- =============================================================================

DECLARE
    env VARCHAR DEFAULT 'DEV';
    db_raw VARCHAR;
BEGIN
    db_raw := 'LIGHTHOUSE_' || :env || '_RAW';

    EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE ' || :db_raw || '.OLTP.oltp_stage';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE ' || :db_raw || '.CRM.crm_stage';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE ' || :db_raw || '.IOT.iot_stage';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE ' || :db_raw || '.PARTNER_FEEDS.partner_stage';
    EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE ' || :db_raw || '.KNOWLEDGE_BASE.kb_stage';

    RETURN 'Stages created for environment: ' || :env;
END;
