-- =============================================================================
-- 08_file_formats.sql — Create file format objects per source
-- =============================================================================
-- Defines reusable file format objects for CSV, JSON, and Parquet ingestion.
-- Formats are created in each relevant RAW schema so COPY INTO statements
-- can reference them directly.
--
-- Prerequisite: 01_databases.sql, 05_schemas.sql
-- Usage:        Run standalone or via deploy.sql. Change 'DEV' below as needed.
-- Idempotency:  Uses CREATE OR REPLACE FILE FORMAT — safe to re-run.
-- =============================================================================

DECLARE
    env VARCHAR DEFAULT 'DEV';
    db_raw VARCHAR;
BEGIN
    db_raw := 'LIGHTHOUSE_' || :env || '_RAW';

    -- OLTP — CSV
    EXECUTE IMMEDIATE
        'CREATE OR REPLACE FILE FORMAT ' || :db_raw || '.OLTP.csv_format
         TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1
         FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
         NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
         EMPTY_FIELD_AS_NULL = TRUE TRIM_SPACE = TRUE
         ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE';

    -- CRM — CSV
    EXECUTE IMMEDIATE
        'CREATE OR REPLACE FILE FORMAT ' || :db_raw || '.CRM.csv_format
         TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1
         FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
         NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
         EMPTY_FIELD_AS_NULL = TRUE TRIM_SPACE = TRUE
         ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE';

    -- IoT — JSON
    EXECUTE IMMEDIATE
        'CREATE OR REPLACE FILE FORMAT ' || :db_raw || '.IOT.json_format
         TYPE = ''JSON'' STRIP_OUTER_ARRAY = TRUE STRIP_NULL_VALUES = FALSE';

    -- Partner Feeds — CSV and Parquet
    EXECUTE IMMEDIATE
        'CREATE OR REPLACE FILE FORMAT ' || :db_raw || '.PARTNER_FEEDS.csv_format
         TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1
         FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
         NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
         EMPTY_FIELD_AS_NULL = TRUE TRIM_SPACE = TRUE
         ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE';

    EXECUTE IMMEDIATE
        'CREATE OR REPLACE FILE FORMAT ' || :db_raw || '.PARTNER_FEEDS.parquet_format
         TYPE = ''PARQUET'' COMPRESSION = ''SNAPPY''';

    -- Knowledge Base — CSV
    EXECUTE IMMEDIATE
        'CREATE OR REPLACE FILE FORMAT ' || :db_raw || '.KNOWLEDGE_BASE.csv_format
         TYPE = ''CSV'' FIELD_DELIMITER = '','' SKIP_HEADER = 1
         FIELD_OPTIONALLY_ENCLOSED_BY = ''"''
         NULL_IF = ('''', ''NULL'', ''null'', ''\\N'')
         EMPTY_FIELD_AS_NULL = TRUE TRIM_SPACE = TRUE';

    RETURN 'File formats created for environment: ' || :env;
END;
