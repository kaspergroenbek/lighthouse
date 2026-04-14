-- =============================================================================
-- load_iot_seeds.sql — Create raw IoT table and load telemetry event seed data
-- =============================================================================
-- Purpose:  Creates the raw telemetry_events table in RAW.IOT with a VARIANT
--           column for the full JSON payload alongside extracted metadata columns,
--           then loads synthetic JSON event files via PUT + COPY INTO.
--
-- Prerequisites:
--   - 01_databases.sql  (LIGHTHOUSE_{ENV}_RAW database)
--   - 05_schemas.sql    (RAW.IOT schema)
--   - 06_stages.sql     (@RAW.IOT.iot_stage)
--   - 08_file_formats.sql (RAW.IOT.json_format)
--
-- Design notes:
--   - event_data (VARIANT) stores the full JSON payload as-is
--   - device_id, event_type, event_timestamp are extracted during COPY INTO
--     for query performance and partition pruning
--   - event_timestamp (source) is preserved separately from _loaded_at (platform)
--     to support downstream deduplication of out-of-order/late-arriving events
--   - _ingestion_date partitions data by load date for lifecycle management
--
-- Idempotency: Uses CREATE OR REPLACE TABLE — safe to re-run.
-- =============================================================================

-- SET env = 'DEV';  -- Uncomment if running standalone

USE WAREHOUSE INGESTION_WH;
USE DATABASE IDENTIFIER('LIGHTHOUSE_' || $env || '_RAW');
USE SCHEMA IOT;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. RAW TABLE DDL
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE TABLE telemetry_events (
    event_data          VARIANT         COMMENT 'Full JSON event payload',
    device_id           VARCHAR(50)     COMMENT 'Extracted device identifier for partitioning',
    event_type          VARCHAR(50)     COMMENT 'Event type: energy_reading, device_status, temperature_reading, alert_event',
    event_timestamp     TIMESTAMP_NTZ   COMMENT 'Source event timestamp (may be out of order)',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _ingestion_date     DATE            DEFAULT CURRENT_DATE() COMMENT 'Partition column for lifecycle management'
)
COMMENT = 'Raw semi-structured telemetry events from NordHjem IoT devices';


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. PUT — Upload JSON event files to internal stage
-- ─────────────────────────────────────────────────────────────────────────────

PUT file://data/iot_events/energy_readings.json      @iot_stage/energy_readings/      AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/iot_events/device_status.json        @iot_stage/device_status/        AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/iot_events/temperature_readings.json @iot_stage/temperature_readings/ AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/iot_events/alert_events.json         @iot_stage/alert_events/         AUTO_COMPRESS = TRUE OVERWRITE = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. COPY INTO — Load JSON events with VARIANT parsing and field extraction
-- ─────────────────────────────────────────────────────────────────────────────
-- Uses a SELECT in COPY INTO to extract device_id, event_type, event_timestamp
-- from the JSON while keeping the full payload in event_data.

COPY INTO telemetry_events (event_data, device_id, event_type, event_timestamp)
    FROM (
        SELECT
            $1                                          AS event_data,
            $1:device_id::VARCHAR(50)                   AS device_id,
            $1:event_type::VARCHAR(50)                  AS event_type,
            $1:event_timestamp::TIMESTAMP_NTZ           AS event_timestamp
        FROM @iot_stage/energy_readings/
    )
    FILE_FORMAT = (FORMAT_NAME = json_format)
    ON_ERROR = 'CONTINUE';

COPY INTO telemetry_events (event_data, device_id, event_type, event_timestamp)
    FROM (
        SELECT
            $1                                          AS event_data,
            $1:device_id::VARCHAR(50)                   AS device_id,
            $1:event_type::VARCHAR(50)                  AS event_type,
            $1:event_timestamp::TIMESTAMP_NTZ           AS event_timestamp
        FROM @iot_stage/device_status/
    )
    FILE_FORMAT = (FORMAT_NAME = json_format)
    ON_ERROR = 'CONTINUE';

COPY INTO telemetry_events (event_data, device_id, event_type, event_timestamp)
    FROM (
        SELECT
            $1                                          AS event_data,
            $1:device_id::VARCHAR(50)                   AS device_id,
            $1:event_type::VARCHAR(50)                  AS event_type,
            $1:event_timestamp::TIMESTAMP_NTZ           AS event_timestamp
        FROM @iot_stage/temperature_readings/
    )
    FILE_FORMAT = (FORMAT_NAME = json_format)
    ON_ERROR = 'CONTINUE';

COPY INTO telemetry_events (event_data, device_id, event_type, event_timestamp)
    FROM (
        SELECT
            $1                                          AS event_data,
            $1:device_id::VARCHAR(50)                   AS device_id,
            $1:event_type::VARCHAR(50)                  AS event_type,
            $1:event_timestamp::TIMESTAMP_NTZ           AS event_timestamp
        FROM @iot_stage/alert_events/
    )
    FILE_FORMAT = (FORMAT_NAME = json_format)
    ON_ERROR = 'CONTINUE';
