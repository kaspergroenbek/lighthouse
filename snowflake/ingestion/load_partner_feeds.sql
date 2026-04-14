-- =============================================================================
-- load_partner_feeds.sql — Create raw partner feed tables and load seed data
-- =============================================================================
-- Purpose:  Creates raw tables in RAW.PARTNER_FEEDS for 3 partner feed types,
--           a quarantine stage for failed files, and an error logging table.
--           Then loads synthetic seed files via PUT + COPY INTO.
--
-- Prerequisites:
--   - 01_databases.sql  (LIGHTHOUSE_{ENV}_RAW database)
--   - 05_schemas.sql    (RAW.PARTNER_FEEDS schema)
--   - 06_stages.sql     (@RAW.PARTNER_FEEDS.partner_stage)
--   - 08_file_formats.sql (RAW.PARTNER_FEEDS.csv_format, parquet_format)
--
-- Partner feed metadata columns:
--   _loaded_at              — Platform ingestion timestamp
--   _source_file_name       — Source file name (METADATA$FILENAME)
--   _source_file_row_number — Row number in source file (METADATA$FILE_ROW_NUMBER)
--
-- Error handling:
--   - Quarantine stage for files that fail schema validation
--   - _file_load_errors table for error logging
--   - ON_ERROR = 'CONTINUE' to load valid records and skip bad ones
--
-- Idempotency: Uses CREATE OR REPLACE — safe to re-run.
-- =============================================================================

USE WAREHOUSE INGESTION_WH;
USE DATABASE LIGHTHOUSE_DEV_RAW;
USE SCHEMA PARTNER_FEEDS;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. QUARANTINE STAGE AND ERROR LOGGING TABLE
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE STAGE quarantine_stage
    COMMENT = 'Quarantine stage for partner feed files that fail validation';

CREATE OR REPLACE TABLE _file_load_errors (
    file_name       VARCHAR(500)    COMMENT 'Name of the file that caused the error',
    error_type      VARCHAR(100)    COMMENT 'Error classification: schema_mismatch, parse_error, etc.',
    error_message   VARCHAR(4000)   COMMENT 'Detailed error message',
    record_count    INTEGER         COMMENT 'Number of records affected',
    logged_at       TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Timestamp when error was logged'
)
COMMENT = 'Error log for partner feed file load failures';


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. RAW TABLE DDL
-- ─────────────────────────────────────────────────────────────────────────────

-- Grid Usage Readings — daily CSV from energy grid operator
CREATE OR REPLACE TABLE grid_usage_readings (
    reading_id              VARCHAR(50)     COMMENT 'Natural key — grid reading identifier',
    meter_id                VARCHAR(50)     COMMENT 'Grid meter identifier',
    household_id            INTEGER         COMMENT 'FK to OLTP households',
    reading_date            DATE            COMMENT 'Date of the grid reading',
    kwh_consumed            NUMBER(12,2)    COMMENT 'Kilowatt-hours consumed',
    kwh_produced            NUMBER(12,2)    COMMENT 'Kilowatt-hours produced (solar export)',
    peak_demand_kw          NUMBER(12,2)    COMMENT 'Peak demand in kilowatts',
    reading_source          VARCHAR(50)     COMMENT 'Source: automatic, manual',
    _loaded_at              TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _source_file_name       VARCHAR(500)    COMMENT 'Source file name (METADATA$FILENAME)',
    _source_file_row_number INTEGER         COMMENT 'Row number in source file (METADATA$FILE_ROW_NUMBER)'
)
COMMENT = 'Raw partner feed — daily grid usage readings from energy grid operator';

-- Installation Certifications — weekly Parquet from partner installers
CREATE OR REPLACE TABLE installation_certifications (
    certification_id        VARCHAR(50)     COMMENT 'Natural key — certification identifier',
    installation_id         INTEGER         COMMENT 'FK to OLTP installations',
    installer_id            VARCHAR(20)     COMMENT 'Partner installer identifier',
    certification_date      DATE            COMMENT 'Date of certification',
    certification_type      VARCHAR(100)    COMMENT 'Type: electrical_safety, device_commissioning',
    expiry_date             DATE            COMMENT 'Certification expiry date',
    status                  VARCHAR(50)     COMMENT 'Status: valid, expired, revoked',
    inspector_name          VARCHAR(255)    COMMENT 'Name of the certifying inspector',
    _loaded_at              TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _source_file_name       VARCHAR(500)    COMMENT 'Source file name (METADATA$FILENAME)',
    _source_file_row_number INTEGER         COMMENT 'Row number in source file (METADATA$FILE_ROW_NUMBER)'
)
COMMENT = 'Raw partner feed — installation certifications from partner installers';

-- Product Catalog Updates — monthly CSV from manufacturer
CREATE OR REPLACE TABLE product_catalog_updates (
    product_id              INTEGER         COMMENT 'Product identifier',
    product_name            VARCHAR(255)    COMMENT 'Product display name',
    category                VARCHAR(50)     COMMENT 'Product category',
    manufacturer            VARCHAR(100)    COMMENT 'Manufacturer name',
    model_number            VARCHAR(50)     COMMENT 'Manufacturer model number',
    specifications          VARCHAR(2000)   COMMENT 'Product specifications text',
    list_price              NUMBER(12,2)    COMMENT 'Manufacturer list price',
    effective_date          DATE            COMMENT 'Price/spec effective date',
    is_discontinued         BOOLEAN         COMMENT 'Whether product is discontinued',
    _loaded_at              TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _source_file_name       VARCHAR(500)    COMMENT 'Source file name (METADATA$FILENAME)',
    _source_file_row_number INTEGER         COMMENT 'Row number in source file (METADATA$FILE_ROW_NUMBER)'
)
COMMENT = 'Raw partner feed — product catalog updates from manufacturer';

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. PUT — Upload seed files to internal stage
-- ─────────────────────────────────────────────────────────────────────────────

PUT file://data/partner_feeds/grid_usage_readings.csv        @partner_stage/grid_usage_readings/        AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/partner_feeds/installation_certifications.csv @partner_stage/installation_certifications/ AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/partner_feeds/product_catalog_updates.csv    @partner_stage/product_catalog_updates/    AUTO_COMPRESS = TRUE OVERWRITE = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. COPY INTO — Load seed data with file-level metadata and error handling
-- ─────────────────────────────────────────────────────────────────────────────

-- Grid Usage Readings (CSV)
COPY INTO grid_usage_readings (
    reading_id, meter_id, household_id, reading_date,
    kwh_consumed, kwh_produced, peak_demand_kw, reading_source,
    _source_file_name, _source_file_row_number
)
    FROM (
        SELECT
            $1, $2, $3, $4, $5, $6, $7, $8,
            METADATA$FILENAME,
            METADATA$FILE_ROW_NUMBER
        FROM @partner_stage/grid_usage_readings/
    )
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'CONTINUE';

-- Installation Certifications (CSV seed — Parquet in production)
COPY INTO installation_certifications (
    certification_id, installation_id, installer_id, certification_date,
    certification_type, expiry_date, status, inspector_name,
    _source_file_name, _source_file_row_number
)
    FROM (
        SELECT
            $1, $2, $3, $4, $5, $6, $7, $8,
            METADATA$FILENAME,
            METADATA$FILE_ROW_NUMBER
        FROM @partner_stage/installation_certifications/
    )
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'CONTINUE';

-- Product Catalog Updates (CSV)
COPY INTO product_catalog_updates (
    product_id, product_name, category, manufacturer,
    model_number, specifications, list_price, effective_date, is_discontinued,
    _source_file_name, _source_file_row_number
)
    FROM (
        SELECT
            $1, $2, $3, $4, $5, $6, $7, $8, $9,
            METADATA$FILENAME,
            METADATA$FILE_ROW_NUMBER
        FROM @partner_stage/product_catalog_updates/
    )
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'CONTINUE';
