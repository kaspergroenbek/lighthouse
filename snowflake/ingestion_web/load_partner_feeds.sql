-- =============================================================================
-- load_partner_feeds.sql — Snowsight-compatible version (INSERT INTO ... VALUES)
-- =============================================================================
-- Purpose:  Creates raw tables in RAW.PARTNER_FEEDS for 3 partner feed types,
--           a quarantine stage for failed files, and an error logging table.
--           Then loads synthetic seed data via INSERT INTO ... VALUES.
--           This version runs in Snowflake's web UI (Snowsight) without SnowSQL.
--
-- Original: lighthouse/snowflake/ingestion/load_partner_feeds.sql (PUT + COPY INTO)
--
-- Partner feed metadata columns:
--   _loaded_at              — Platform ingestion timestamp (DEFAULT, excluded from INSERT)
--   _source_file_name       — Source file name
--   _source_file_row_number — Row number in source file
--
-- Idempotency: Uses CREATE OR REPLACE — safe to re-run.
-- =============================================================================

SET LIGHTHOUSE_ENV = 'DEV';
SET LIGHTHOUSE_RAW_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_RAW';

USE WAREHOUSE INGESTION_WH;
EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_RAW_DB;
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
-- 3. INSERT — Load seed data via INSERT INTO ... VALUES
-- ─────────────────────────────────────────────────────────────────────────────
-- _loaded_at is excluded (DEFAULT). _source_file_name and _source_file_row_number are included.

-- Grid Usage Readings
INSERT INTO grid_usage_readings (reading_id, meter_id, household_id, reading_date, kwh_consumed, kwh_produced, peak_demand_kw, reading_source, _source_file_name, _source_file_row_number)
VALUES
    ('GR-20250201-001', 'MTR-2001', 2001, '2025-02-01', 24.1, 0.0, 3.2, 'automatic', 'grid_usage_readings.csv', 2),
    ('GR-20250201-002', 'MTR-2002', 2002, '2025-02-01', 18.6, 0.0, 2.8, 'automatic', 'grid_usage_readings.csv', 3),
    ('GR-20250201-003', 'MTR-2003', 2003, '2025-02-01', 78.9, 0.0, 12.4, 'automatic', 'grid_usage_readings.csv', 4),
    ('GR-20250201-004', 'MTR-2004', 2004, '2025-02-01', 14.2, 0.0, 2.1, 'automatic', 'grid_usage_readings.csv', 5),
    ('GR-20250201-005', 'MTR-2005', 2005, '2025-02-01', 112.5, 0.0, 18.7, 'automatic', 'grid_usage_readings.csv', 6),
    ('GR-20250201-006', 'MTR-2006', 2006, '2025-02-01', 11.3, 0.0, 1.8, 'automatic', 'grid_usage_readings.csv', 7),
    ('GR-20250201-007', 'MTR-2008', 2008, '2025-02-01', 22.8, 0.0, 3.5, 'automatic', 'grid_usage_readings.csv', 8),
    ('GR-20250201-008', 'MTR-2009', 2009, '2025-02-01', 71.4, 0.0, 11.2, 'automatic', 'grid_usage_readings.csv', 9),
    ('GR-20250201-009', 'MTR-2010', 2010, '2025-02-01', 9.8, 0.0, 1.5, 'automatic', 'grid_usage_readings.csv', 10),
    ('GR-20250201-010', 'MTR-2011', 2011, '2025-02-01', 19.3, 0.0, 2.9, 'automatic', 'grid_usage_readings.csv', 11),
    ('GR-20250202-001', 'MTR-2001', 2001, '2025-02-02', 25.7, 0.0, 3.4, 'automatic', 'grid_usage_readings.csv', 12),
    ('GR-20250202-002', 'MTR-2002', 2002, '2025-02-02', 19.4, 0.0, 2.9, 'automatic', 'grid_usage_readings.csv', 13),
    ('GR-20250202-003', 'MTR-2003', 2003, '2025-02-02', 81.3, 0.0, 13.1, 'automatic', 'grid_usage_readings.csv', 14),
    ('GR-20250202-004', 'MTR-2004', 2004, '2025-02-02', 15.1, 0.0, 2.3, 'automatic', 'grid_usage_readings.csv', 15),
    ('GR-20250202-005', 'MTR-2005', 2005, '2025-02-02', 115.2, 0.0, 19.2, 'automatic', 'grid_usage_readings.csv', 16),
    ('GR-20250202-006', 'MTR-2006', 2006, '2025-02-02', 12.1, 0.0, 1.9, 'automatic', 'grid_usage_readings.csv', 17),
    ('GR-20250202-007', 'MTR-2008', 2008, '2025-02-02', 23.5, 0.0, 3.6, 'automatic', 'grid_usage_readings.csv', 18),
    ('GR-20250202-008', 'MTR-2009', 2009, '2025-02-02', 73.9, 0.0, 11.8, 'automatic', 'grid_usage_readings.csv', 19),
    ('GR-20250202-009', 'MTR-2010', 2010, '2025-02-02', 10.2, 0.0, 1.6, 'automatic', 'grid_usage_readings.csv', 20),
    ('GR-20250202-010', 'MTR-2011', 2011, '2025-02-02', 20.1, 0.0, 3.0, 'automatic', 'grid_usage_readings.csv', 21),
    ('GR-20250203-001', 'MTR-2001', 2001, '2025-02-03', 23.4, 0.0, 3.1, 'automatic', 'grid_usage_readings.csv', 22),
    ('GR-20250203-002', 'MTR-2002', 2002, '2025-02-03', 17.9, 0.0, 2.7, 'automatic', 'grid_usage_readings.csv', 23),
    ('GR-20250203-003', 'MTR-2003', 2003, '2025-02-03', 76.5, 0.0, 12.0, 'automatic', 'grid_usage_readings.csv', 24),
    ('GR-20250203-004', 'MTR-2004', 2004, '2025-02-03', 13.8, 0.0, 2.0, 'automatic', 'grid_usage_readings.csv', 25),
    ('GR-20250203-005', 'MTR-2005', 2005, '2025-02-03', 108.7, 0.0, 18.1, 'automatic', 'grid_usage_readings.csv', 26),
    ('GR-20250203-006', 'MTR-2006', 2006, '2025-02-03', 10.9, 0.0, 1.7, 'automatic', 'grid_usage_readings.csv', 27),
    ('GR-20250203-007', 'MTR-2008', 2008, '2025-02-03', 21.6, 0.0, 3.3, 'automatic', 'grid_usage_readings.csv', 28),
    ('GR-20250203-008', 'MTR-2009', 2009, '2025-02-03', 69.2, 0.0, 10.9, 'automatic', 'grid_usage_readings.csv', 29),
    ('GR-20250203-009', 'MTR-2010', 2010, '2025-02-03', 9.5, 0.0, 1.4, 'manual', 'grid_usage_readings.csv', 30),
    ('GR-20250203-010', 'MTR-2011', 2011, '2025-02-03', 18.7, 0.0, 2.8, 'automatic', 'grid_usage_readings.csv', 31);

-- Installation Certifications
INSERT INTO installation_certifications (certification_id, installation_id, installer_id, certification_date, certification_type, expiry_date, status, inspector_name, _source_file_name, _source_file_row_number)
VALUES
    ('CERT-001', 3001, 'P001', '2025-01-11', 'electrical_safety', '2026-01-11', 'valid', 'Anders Møller', 'installation_certifications.csv', 2),
    ('CERT-002', 3001, 'P001', '2025-01-11', 'device_commissioning', '2026-01-11', 'valid', 'Anders Møller', 'installation_certifications.csv', 3),
    ('CERT-003', 3002, 'P002', '2025-01-13', 'electrical_safety', '2026-01-13', 'valid', 'Sven Eriksson', 'installation_certifications.csv', 4),
    ('CERT-004', 3002, 'P002', '2025-01-13', 'device_commissioning', '2026-01-13', 'valid', 'Sven Eriksson', 'installation_certifications.csv', 5),
    ('CERT-005', 3003, 'P001', '2025-01-16', 'electrical_safety', '2026-01-16', 'valid', 'Anders Møller', 'installation_certifications.csv', 6),
    ('CERT-006', 3003, 'P001', '2025-01-16', 'device_commissioning', '2026-01-16', 'valid', 'Anders Møller', 'installation_certifications.csv', 7),
    ('CERT-007', 3003, 'P001', '2025-01-16', 'commercial_compliance', '2026-01-16', 'valid', 'Knut Larsen', 'installation_certifications.csv', 8),
    ('CERT-008', 3004, 'P003', '2025-01-19', 'electrical_safety', '2026-01-19', 'valid', 'Bjarne Holm', 'installation_certifications.csv', 9),
    ('CERT-009', 3004, 'P003', '2025-01-19', 'device_commissioning', '2026-01-19', 'valid', 'Bjarne Holm', 'installation_certifications.csv', 10),
    ('CERT-010', 3005, 'P002', '2025-01-21', 'electrical_safety', '2026-01-21', 'valid', 'Sven Eriksson', 'installation_certifications.csv', 11),
    ('CERT-011', 3005, 'P002', '2025-01-21', 'commercial_compliance', '2026-01-21', 'valid', 'Knut Larsen', 'installation_certifications.csv', 12),
    ('CERT-012', 3006, 'P001', '2025-01-23', 'electrical_safety', '2026-01-23', 'valid', 'Anders Møller', 'installation_certifications.csv', 13),
    ('CERT-013', 3006, 'P001', '2025-01-23', 'device_commissioning', '2026-01-23', 'valid', 'Anders Møller', 'installation_certifications.csv', 14),
    ('CERT-014', 3007, 'P003', '2025-01-26', 'electrical_safety', '2026-01-26', 'valid', 'Bjarne Holm', 'installation_certifications.csv', 15),
    ('CERT-015', 3007, 'P003', '2025-01-26', 'device_commissioning', '2026-01-26', 'valid', 'Bjarne Holm', 'installation_certifications.csv', 16),
    ('CERT-016', 3008, 'P002', '2025-01-29', 'electrical_safety', '2026-01-29', 'valid', 'Sven Eriksson', 'installation_certifications.csv', 17),
    ('CERT-017', 3008, 'P002', '2025-01-29', 'device_commissioning', '2026-01-29', 'valid', 'Sven Eriksson', 'installation_certifications.csv', 18),
    ('CERT-018', 3009, 'P001', '2025-02-02', 'electrical_safety', '2026-02-02', 'valid', 'Anders Møller', 'installation_certifications.csv', 19),
    ('CERT-019', 3010, 'P003', '2025-02-06', 'electrical_safety', '2026-02-06', 'valid', 'Bjarne Holm', 'installation_certifications.csv', 20),
    ('CERT-020', 3010, 'P003', '2025-02-06', 'device_commissioning', '2026-02-06', 'valid', 'Bjarne Holm', 'installation_certifications.csv', 21),
    ('CERT-021', 3003, 'P001', '2025-02-16', 'maintenance_inspection', '2025-08-16', 'valid', 'Anders Møller', 'installation_certifications.csv', 22);

-- Product Catalog Updates
INSERT INTO product_catalog_updates (product_id, product_name, category, manufacturer, model_number, specifications, list_price, effective_date, is_discontinued, _source_file_name, _source_file_row_number)
VALUES
    (7001, 'Smart Thermostat v2', 'thermostat', 'NordHjem', 'NH-TH-V2', 'WiFi 802.11 b/g/n, 3.5in touchscreen, learning algorithm, geofencing, voice control compatible', 1299.00, '2025-01-01', FALSE, 'product_catalog_updates.csv', 2),
    (7002, 'Energy Meter Pro', 'energy_meter', 'NordHjem', 'NH-EM-PRO', '3-phase CT clamp, real-time monitoring, grid export measurement, 0.5% accuracy class', 1899.00, '2025-01-01', FALSE, 'product_catalog_updates.csv', 3),
    (7006, 'Temp Sensor Mini', 'temperature_sensor', 'NordHjem', 'NH-TS-MINI', 'Battery powered, Zigbee 3.0, temperature + humidity, 2-year battery life', 399.00, '2025-01-01', FALSE, 'product_catalog_updates.csv', 4),
    (7008, 'Solar Integration Kit', 'solar_monitor', 'NordHjem', 'NH-SOL-V1', 'PV inverter monitoring, grid export optimization, compatible with major inverter brands', 3499.00, '2025-01-01', FALSE, 'product_catalog_updates.csv', 5),
    (7001, 'Smart Thermostat v2', 'thermostat', 'NordHjem', 'NH-TH-V2', 'WiFi 802.11 b/g/n/ac, 3.5in touchscreen, learning algorithm, geofencing, voice control, Matter compatible', 1349.00, '2025-02-01', FALSE, 'product_catalog_updates.csv', 6),
    (7002, 'Energy Meter Pro', 'energy_meter', 'NordHjem', 'NH-EM-PRO', '3-phase CT clamp, real-time monitoring, grid export measurement, 0.5% accuracy class, Zigbee gateway', 1949.00, '2025-02-01', FALSE, 'product_catalog_updates.csv', 7),
    (7008, 'Solar Integration Kit', 'solar_monitor', 'NordHjem', 'NH-SOL-V1', 'PV inverter monitoring, grid export optimization, compatible with major inverter brands', 3499.00, '2025-03-01', TRUE, 'product_catalog_updates.csv', 8);


