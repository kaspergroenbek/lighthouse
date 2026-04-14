-- =============================================================================
-- 08_file_formats.sql — Create file format objects per source
-- =============================================================================
-- Purpose:  Defines reusable file format objects for CSV, JSON, and Parquet
--           ingestion. Formats are created in each relevant RAW schema so
--           COPY INTO statements can reference them directly.
--
-- Prerequisite: 01_databases.sql, 05_schemas.sql
--
-- File formats:
--   CSV    — comma-delimited, skip header, quoted fields, null handling
--   JSON   — strip outer array for batch JSON files
--   Parquet — Snappy compression (Snowflake default)
--
-- Idempotency: Uses CREATE OR REPLACE FILE FORMAT — safe to re-run.
-- =============================================================================

-- Inherit env from deploy.sql, or set manually if running standalone
-- SET env = 'DEV';

-- ─────────────────────────────────────────────────────────────────────────────
-- OLTP schema — CSV format for CDC seed files
-- ─────────────────────────────────────────────────────────────────────────────

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.OLTP.csv_format
     TYPE = ''CSV''
     FIELD_DELIMITER = '',''
     SKIP_HEADER = 1
     FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
     NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
     EMPTY_FIELD_AS_NULL = TRUE
     TRIM_SPACE = TRUE
     ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
     COMMENT = ''CSV format for OLTP CDC seed data''';

-- ─────────────────────────────────────────────────────────────────────────────
-- CRM schema — CSV format for SaaS connector seed files
-- ─────────────────────────────────────────────────────────────────────────────

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.CRM.csv_format
     TYPE = ''CSV''
     FIELD_DELIMITER = '',''
     SKIP_HEADER = 1
     FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
     NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
     EMPTY_FIELD_AS_NULL = TRUE
     TRIM_SPACE = TRUE
     ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
     COMMENT = ''CSV format for CRM SaaS connector seed data''';

-- ─────────────────────────────────────────────────────────────────────────────
-- IoT schema — JSON format for telemetry event files
-- ─────────────────────────────────────────────────────────────────────────────

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.IOT.json_format
     TYPE = ''JSON''
     STRIP_OUTER_ARRAY = TRUE
     STRIP_NULL_VALUES = FALSE
     COMMENT = ''JSON format for IoT telemetry event files''';

-- ─────────────────────────────────────────────────────────────────────────────
-- Partner Feeds schema — CSV and Parquet formats
-- ─────────────────────────────────────────────────────────────────────────────

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.PARTNER_FEEDS.csv_format
     TYPE = ''CSV''
     FIELD_DELIMITER = '',''
     SKIP_HEADER = 1
     FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
     NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
     EMPTY_FIELD_AS_NULL = TRUE
     TRIM_SPACE = TRUE
     ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
     COMMENT = ''CSV format for partner feed files''';

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.PARTNER_FEEDS.parquet_format
     TYPE = ''PARQUET''
     COMPRESSION = ''SNAPPY''
     COMMENT = ''Parquet format for partner feed files''';

-- ─────────────────────────────────────────────────────────────────────────────
-- Knowledge Base schema — CSV format for document metadata
-- ─────────────────────────────────────────────────────────────────────────────

EXECUTE IMMEDIATE
    'CREATE OR REPLACE FILE FORMAT LIGHTHOUSE_' || $env || '_RAW.KNOWLEDGE_BASE.csv_format
     TYPE = ''CSV''
     FIELD_DELIMITER = '',''
     SKIP_HEADER = 1
     FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
     NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
     EMPTY_FIELD_AS_NULL = TRUE
     TRIM_SPACE = TRUE
     COMMENT = ''CSV format for knowledge base document metadata''';
