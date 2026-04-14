-- =============================================================================
-- deploy.sql — Lighthouse infrastructure deployment (all-in-one)
-- =============================================================================
-- Purpose:  Provisions a complete Lighthouse environment in one script.
--           Works in Snowsight SQL files, SnowSQL, or any SQL client.
--
-- Usage:    Change the env variable below to your target environment,
--           then select all and run.
--
-- Environment: Valid values: DEV, STAGING, PROD
-- Idempotency: All statements use IF NOT EXISTS or OR REPLACE — safe to re-run.
-- =============================================================================

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  SET YOUR TARGET ENVIRONMENT HERE                                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
SET env = 'DEV';


-- ═══════════════════════════════════════════════════════════════════════════
-- 1. DATABASES
-- ═══════════════════════════════════════════════════════════════════════════

EXECUTE IMMEDIATE
    'CREATE DATABASE IF NOT EXISTS LIGHTHOUSE_' || $env || '_RAW
     COMMENT = ''Lighthouse raw ingestion layer — landing zone for source system data''';

EXECUTE IMMEDIATE
    'CREATE DATABASE IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS
     COMMENT = ''Lighthouse analytics layer — dbt-managed staging, intermediate, marts, and semantic models''';

EXECUTE IMMEDIATE
    'CREATE DATABASE IF NOT EXISTS LIGHTHOUSE_' || $env || '_SERVING
     COMMENT = ''Lighthouse serving layer — Dynamic Tables and real-time data products''';


-- ═══════════════════════════════════════════════════════════════════════════
-- 2. WAREHOUSES (environment-independent)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE WAREHOUSE IF NOT EXISTS INGESTION_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Lighthouse ingestion workloads — COPY INTO, seed loading';

CREATE WAREHOUSE IF NOT EXISTS TRANSFORM_WH
    WITH WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Lighthouse transformation workloads — dbt build';

CREATE WAREHOUSE IF NOT EXISTS SERVING_WH
    WITH WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Lighthouse serving workloads — Streamlit, BI queries, Dynamic Tables';

CREATE WAREHOUSE IF NOT EXISTS AI_WH
    WITH WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Lighthouse AI workloads — Cortex Analyst, Cortex Search';


-- ═══════════════════════════════════════════════════════════════════════════
-- 3. ROLES (environment-independent)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE ROLE IF NOT EXISTS LIGHTHOUSE_READER
    COMMENT = 'Read-only access to analytics and serving data products';

CREATE ROLE IF NOT EXISTS LIGHTHOUSE_TRANSFORMER
    COMMENT = 'dbt transformation role — can create/modify objects in analytics schemas';

CREATE ROLE IF NOT EXISTS LIGHTHOUSE_ENGINEER
    COMMENT = 'Data engineering role — full access to all databases and warehouses';

CREATE ROLE IF NOT EXISTS LIGHTHOUSE_ADMIN
    COMMENT = 'Platform admin role — manages grants, databases, and platform configuration';

GRANT ROLE LIGHTHOUSE_READER TO ROLE LIGHTHOUSE_TRANSFORMER;
GRANT ROLE LIGHTHOUSE_TRANSFORMER TO ROLE LIGHTHOUSE_ENGINEER;
GRANT ROLE LIGHTHOUSE_ENGINEER TO ROLE LIGHTHOUSE_ADMIN;
GRANT ROLE LIGHTHOUSE_ADMIN TO ROLE SYSADMIN;


-- ═══════════════════════════════════════════════════════════════════════════
-- 4. GRANTS
-- ═══════════════════════════════════════════════════════════════════════════

-- READER — read-only on analytics and serving
EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE LIGHTHOUSE_' || $env || '_RAW TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT USAGE ON ALL SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT USAGE ON ALL SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT SELECT ON ALL TABLES IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE TABLES IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT SELECT ON ALL VIEWS IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE VIEWS IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT SELECT ON ALL TABLES IN DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE TABLES IN DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT SELECT ON ALL VIEWS IN DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_READER';
EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE VIEWS IN DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_READER';
GRANT USAGE ON WAREHOUSE SERVING_WH TO ROLE LIGHTHOUSE_READER;

-- TRANSFORMER — dbt transformation role
GRANT USAGE ON WAREHOUSE TRANSFORM_WH TO ROLE LIGHTHOUSE_TRANSFORMER;
EXECUTE IMMEDIATE 'GRANT CREATE TABLE ON ALL SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_TRANSFORMER';
EXECUTE IMMEDIATE 'GRANT CREATE TABLE ON FUTURE SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_TRANSFORMER';
EXECUTE IMMEDIATE 'GRANT CREATE VIEW ON ALL SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_TRANSFORMER';
EXECUTE IMMEDIATE 'GRANT CREATE VIEW ON FUTURE SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_TRANSFORMER';
EXECUTE IMMEDIATE 'GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_TRANSFORMER';
EXECUTE IMMEDIATE 'GRANT INSERT, UPDATE, DELETE ON FUTURE TABLES IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_TRANSFORMER';


-- ENGINEER — full access to all databases and warehouses
GRANT USAGE ON WAREHOUSE INGESTION_WH TO ROLE LIGHTHOUSE_ENGINEER;
GRANT USAGE ON WAREHOUSE TRANSFORM_WH TO ROLE LIGHTHOUSE_ENGINEER;
GRANT USAGE ON WAREHOUSE SERVING_WH TO ROLE LIGHTHOUSE_ENGINEER;
GRANT USAGE ON WAREHOUSE AI_WH TO ROLE LIGHTHOUSE_ENGINEER;
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON DATABASE LIGHTHOUSE_' || $env || '_RAW TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_RAW TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_RAW TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE LIGHTHOUSE_' || $env || '_RAW TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE LIGHTHOUSE_' || $env || '_RAW TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE LIGHTHOUSE_' || $env || '_ANALYTICS TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_ENGINEER';
EXECUTE IMMEDIATE 'GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE LIGHTHOUSE_' || $env || '_SERVING TO ROLE LIGHTHOUSE_ENGINEER';

-- ADMIN — account-level administration
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE LIGHTHOUSE_ADMIN;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE LIGHTHOUSE_ADMIN;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE LIGHTHOUSE_ADMIN;
GRANT CREATE ROLE ON ACCOUNT TO ROLE LIGHTHOUSE_ADMIN;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE LIGHTHOUSE_ADMIN;


-- ═══════════════════════════════════════════════════════════════════════════
-- 5. SCHEMAS
-- ═══════════════════════════════════════════════════════════════════════════

-- RAW schemas — one per source system
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_RAW.OLTP COMMENT = ''CDC raw tables from NordHjem PostgreSQL OLTP system''';
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_RAW.CRM COMMENT = ''SaaS connector raw tables from NordHjem CRM platform''';
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_RAW.IOT COMMENT = ''Streaming telemetry raw tables from smart home devices''';
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_RAW.PARTNER_FEEDS COMMENT = ''Batch file raw tables from energy grid operators and partners''';
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_RAW.KNOWLEDGE_BASE COMMENT = ''Document tracking, extracted text, and chunked content''';

-- ANALYTICS schemas — dbt transformation layers + governance
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.STAGING COMMENT = ''dbt staging models''';
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.INTERMEDIATE COMMENT = ''dbt intermediate models''';
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.MARTS COMMENT = ''dbt marts — Kimball star schema''';
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.SNAPSHOTS COMMENT = ''dbt SCD Type 2 snapshots''';
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.SEMANTIC COMMENT = ''Semantic views for Cortex Analyst''';
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.TEST_RESULTS COMMENT = ''dbt test result history''';
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_ANALYTICS.GOVERNANCE COMMENT = ''Governance objects — tags, masking, row access''';

-- SERVING schemas
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_' || $env || '_SERVING.REALTIME COMMENT = ''Dynamic Tables for near-real-time serving''';


-- ═══════════════════════════════════════════════════════════════════════════
-- 6. STAGES
-- ═══════════════════════════════════════════════════════════════════════════

EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE LIGHTHOUSE_' || $env || '_RAW.OLTP.oltp_stage COMMENT = ''Internal stage for OLTP CDC seed data files''';
EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE LIGHTHOUSE_' || $env || '_RAW.CRM.crm_stage COMMENT = ''Internal stage for CRM SaaS connector seed data files''';
EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE LIGHTHOUSE_' || $env || '_RAW.IOT.iot_stage COMMENT = ''Internal stage for IoT telemetry JSON event files''';
EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE LIGHTHOUSE_' || $env || '_RAW.PARTNER_FEEDS.partner_stage COMMENT = ''Internal stage for partner feed CSV and Parquet files''';
EXECUTE IMMEDIATE 'CREATE OR REPLACE STAGE LIGHTHOUSE_' || $env || '_RAW.KNOWLEDGE_BASE.kb_stage COMMENT = ''Internal stage for knowledge base document files''';


-- ═══════════════════════════════════════════════════════════════════════════
-- 7. INTEGRATIONS (templates — all commented out for Standard/trial)
-- ═══════════════════════════════════════════════════════════════════════════
-- See snowflake/infrastructure/07_integrations.sql for S3/Azure templates.
-- Uncomment and configure when deploying to production with external stages.


-- ═══════════════════════════════════════════════════════════════════════════
-- 8. FILE FORMATS
-- ═══════════════════════════════════════════════════════════════════════════

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.OLTP.csv_format
     TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1
     FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
     NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
     EMPTY_FIELD_AS_NULL = TRUE TRIM_SPACE = TRUE
     ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
     COMMENT = ''CSV format for OLTP CDC seed data''';

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.CRM.csv_format
     TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1
     FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
     NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
     EMPTY_FIELD_AS_NULL = TRUE TRIM_SPACE = TRUE
     ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
     COMMENT = ''CSV format for CRM SaaS connector seed data''';

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.IOT.json_format
     TYPE = ''JSON'' STRIP_OUTER_ARRAY = TRUE STRIP_NULL_VALUES = FALSE
     COMMENT = ''JSON format for IoT telemetry event files''';

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.PARTNER_FEEDS.csv_format
     TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1
     FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
     NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
     EMPTY_FIELD_AS_NULL = TRUE TRIM_SPACE = TRUE
     ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
     COMMENT = ''CSV format for partner feed files''';

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.PARTNER_FEEDS.parquet_format
     TYPE = ''PARQUET'' COMPRESSION = ''SNAPPY''
     COMMENT = ''Parquet format for partner feed files''';

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.KNOWLEDGE_BASE.csv_format
     TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1
     FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
     NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
     EMPTY_FIELD_AS_NULL = TRUE TRIM_SPACE = TRUE
     COMMENT = ''CSV format for knowledge base document metadata''';


-- ═══════════════════════════════════════════════════════════════════════════
-- DONE
-- ═══════════════════════════════════════════════════════════════════════════
SELECT 'Lighthouse infrastructure deployment complete for environment: ' || $env AS status;