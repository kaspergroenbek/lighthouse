-- =============================================================================
-- load_oltp_seeds.sql — Snowsight-compatible version (INSERT INTO ... VALUES)
-- =============================================================================
-- Purpose:  Creates raw tables in RAW.OLTP for all 11 OLTP entities with CDC
--           metadata columns, then loads synthetic seed data via INSERT INTO.
--           This version runs in Snowflake's web UI (Snowsight) without SnowSQL.
--
-- Original: lighthouse/snowflake/ingestion/load_oltp_seeds.sql (PUT + COPY INTO)
--
-- CDC metadata columns:
--   _op                 — Change operation (INSERT, UPDATE, DELETE)
--   _source_ts          — Source system timestamp of the change
--   _loaded_at          — Platform ingestion timestamp (auto-populated via DEFAULT)
--   _connector_batch_id — CDC connector batch identifier
--
-- Idempotency: Uses CREATE OR REPLACE TABLE — safe to re-run.
-- =============================================================================

SET LIGHTHOUSE_ENV = '{{ env }}';
SET LIGHTHOUSE_RAW_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_RAW';

USE WAREHOUSE INGESTION_WH;
EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_RAW_DB;
USE SCHEMA OLTP;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. RAW TABLE DDL
-- ─────────────────────────────────────────────────────────────────────────────

-- Customers — residential and commercial customer records
CREATE OR REPLACE TABLE customers (
    _op                 VARCHAR(10)     COMMENT 'CDC operation type: INSERT, UPDATE, DELETE',
    _source_ts          TIMESTAMP_NTZ   COMMENT 'Source system change timestamp',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _connector_batch_id VARCHAR(50)     COMMENT 'CDC connector batch identifier',
    customer_id         INTEGER         COMMENT 'Natural key — customer identifier',
    email               VARCHAR(255)    COMMENT 'Customer email address',
    first_name          VARCHAR(100)    COMMENT 'Customer first name',
    last_name           VARCHAR(100)    COMMENT 'Customer last name',
    phone               VARCHAR(50)     COMMENT 'Customer phone number',
    address             VARCHAR(255)    COMMENT 'Street address',
    postal_code         VARCHAR(20)     COMMENT 'Postal/ZIP code',
    municipality        VARCHAR(100)    COMMENT 'Municipality or city',
    region              VARCHAR(100)    COMMENT 'Geographic region',
    country             VARCHAR(10)     COMMENT 'ISO country code',
    segment             VARCHAR(50)     COMMENT 'Customer segment: residential, commercial',
    status              VARCHAR(50)     COMMENT 'Customer status: active, inactive, churned',
    created_at          TIMESTAMP_NTZ   COMMENT 'Record creation timestamp in source',
    updated_at          TIMESTAMP_NTZ   COMMENT 'Record last update timestamp in source'
)
COMMENT = 'Raw CDC data for NordHjem OLTP customers';

-- Households — residential and commercial sites/properties
CREATE OR REPLACE TABLE households (
    _op                 VARCHAR(10)     COMMENT 'CDC operation type',
    _source_ts          TIMESTAMP_NTZ   COMMENT 'Source system change timestamp',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _connector_batch_id VARCHAR(50)     COMMENT 'CDC connector batch identifier',
    household_id        INTEGER         COMMENT 'Natural key — household/site identifier',
    customer_id         INTEGER         COMMENT 'FK to customers',
    address             VARCHAR(255)    COMMENT 'Street address',
    postal_code         VARCHAR(20)     COMMENT 'Postal/ZIP code',
    municipality        VARCHAR(100)    COMMENT 'Municipality or city',
    country             VARCHAR(10)     COMMENT 'ISO country code',
    household_type      VARCHAR(50)     COMMENT 'Type: apartment, house, office',
    created_at          TIMESTAMP_NTZ   COMMENT 'Record creation timestamp in source',
    updated_at          TIMESTAMP_NTZ   COMMENT 'Record last update timestamp in source'
)
COMMENT = 'Raw CDC data for NordHjem OLTP households/sites';

-- Installations — device installation events at households
CREATE OR REPLACE TABLE installations (
    _op                 VARCHAR(10)     COMMENT 'CDC operation type',
    _source_ts          TIMESTAMP_NTZ   COMMENT 'Source system change timestamp',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _connector_batch_id VARCHAR(50)     COMMENT 'CDC connector batch identifier',
    installation_id     INTEGER         COMMENT 'Natural key — installation identifier',
    household_id        INTEGER         COMMENT 'FK to households',
    installation_date   DATE            COMMENT 'Scheduled or actual installation date',
    installer_partner_id VARCHAR(20)    COMMENT 'Partner installer identifier',
    status              VARCHAR(50)     COMMENT 'Status: scheduled, completed, cancelled',
    notes               VARCHAR(500)    COMMENT 'Installation notes',
    created_at          TIMESTAMP_NTZ   COMMENT 'Record creation timestamp in source',
    updated_at          TIMESTAMP_NTZ   COMMENT 'Record last update timestamp in source'
)
COMMENT = 'Raw CDC data for NordHjem OLTP device installations';

-- Devices — physical smart home devices
CREATE OR REPLACE TABLE devices (
    _op                 VARCHAR(10)     COMMENT 'CDC operation type',
    _source_ts          TIMESTAMP_NTZ   COMMENT 'Source system change timestamp',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _connector_batch_id VARCHAR(50)     COMMENT 'CDC connector batch identifier',
    device_id           INTEGER         COMMENT 'Natural key — device identifier',
    device_serial       VARCHAR(50)     COMMENT 'Device serial number',
    household_id        INTEGER         COMMENT 'FK to households',
    device_type         VARCHAR(50)     COMMENT 'Type: thermostat, energy_meter, temperature_sensor',
    manufacturer        VARCHAR(100)    COMMENT 'Device manufacturer',
    model               VARCHAR(100)    COMMENT 'Device model name',
    firmware_version    VARCHAR(20)     COMMENT 'Current firmware version',
    installed_at        DATE            COMMENT 'Installation date',
    status              VARCHAR(50)     COMMENT 'Status: active, inactive, decommissioned',
    created_at          TIMESTAMP_NTZ   COMMENT 'Record creation timestamp in source',
    updated_at          TIMESTAMP_NTZ   COMMENT 'Record last update timestamp in source'
)
COMMENT = 'Raw CDC data for NordHjem OLTP smart home devices';

-- Contracts — service contracts between customers and NordHjem
CREATE OR REPLACE TABLE contracts (
    _op                 VARCHAR(10)     COMMENT 'CDC operation type',
    _source_ts          TIMESTAMP_NTZ   COMMENT 'Source system change timestamp',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _connector_batch_id VARCHAR(50)     COMMENT 'CDC connector batch identifier',
    contract_id         INTEGER         COMMENT 'Natural key — contract identifier',
    customer_id         INTEGER         COMMENT 'FK to customers',
    household_id        INTEGER         COMMENT 'FK to households',
    product_id          INTEGER         COMMENT 'FK to products',
    tariff_plan_id      INTEGER         COMMENT 'FK to tariff_plans',
    contract_type       VARCHAR(50)     COMMENT 'Type: residential_energy, commercial_energy',
    status              VARCHAR(50)     COMMENT 'Status: active, renewed, cancelled, expired',
    start_date          DATE            COMMENT 'Contract start date',
    end_date            DATE            COMMENT 'Contract end date',
    monthly_amount      NUMBER(12,2)    COMMENT 'Monthly subscription amount (DKK/SEK/NOK)',
    created_at          TIMESTAMP_NTZ   COMMENT 'Record creation timestamp in source',
    updated_at          TIMESTAMP_NTZ   COMMENT 'Record last update timestamp in source'
)
COMMENT = 'Raw CDC data for NordHjem OLTP service contracts';

-- Tariff Plans — energy pricing plans
CREATE OR REPLACE TABLE tariff_plans (
    _op                 VARCHAR(10)     COMMENT 'CDC operation type',
    _source_ts          TIMESTAMP_NTZ   COMMENT 'Source system change timestamp',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _connector_batch_id VARCHAR(50)     COMMENT 'CDC connector batch identifier',
    tariff_plan_id      INTEGER         COMMENT 'Natural key — tariff plan identifier',
    plan_name           VARCHAR(100)    COMMENT 'Plan display name',
    plan_type           VARCHAR(50)     COMMENT 'Type: fixed, variable, green, commercial',
    price_per_kwh       NUMBER(12,2)    COMMENT 'Price per kilowatt-hour',
    monthly_base_fee    NUMBER(12,2)    COMMENT 'Monthly base fee',
    valid_from          DATE            COMMENT 'Plan validity start date',
    valid_to            DATE            COMMENT 'Plan validity end date',
    created_at          TIMESTAMP_NTZ   COMMENT 'Record creation timestamp in source',
    updated_at          TIMESTAMP_NTZ   COMMENT 'Record last update timestamp in source'
)
COMMENT = 'Raw CDC data for NordHjem OLTP tariff/pricing plans';

-- Products — NordHjem product catalog
CREATE OR REPLACE TABLE products (
    _op                 VARCHAR(10)     COMMENT 'CDC operation type',
    _source_ts          TIMESTAMP_NTZ   COMMENT 'Source system change timestamp',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _connector_batch_id VARCHAR(50)     COMMENT 'CDC connector batch identifier',
    product_id          INTEGER         COMMENT 'Natural key — product identifier',
    product_name        VARCHAR(255)    COMMENT 'Product display name',
    category            VARCHAR(50)     COMMENT 'Category: device, bundle, service',
    description         VARCHAR(500)    COMMENT 'Product description',
    pricing_tier        VARCHAR(50)     COMMENT 'Pricing tier: standard, premium',
    is_active           BOOLEAN         COMMENT 'Whether product is currently active',
    created_at          TIMESTAMP_NTZ   COMMENT 'Record creation timestamp in source',
    updated_at          TIMESTAMP_NTZ   COMMENT 'Record last update timestamp in source'
)
COMMENT = 'Raw CDC data for NordHjem OLTP product catalog';

-- Services — service offerings
CREATE OR REPLACE TABLE services (
    _op                 VARCHAR(10)     COMMENT 'CDC operation type',
    _source_ts          TIMESTAMP_NTZ   COMMENT 'Source system change timestamp',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _connector_batch_id VARCHAR(50)     COMMENT 'CDC connector batch identifier',
    service_id          INTEGER         COMMENT 'Natural key — service identifier',
    service_name        VARCHAR(255)    COMMENT 'Service display name',
    category            VARCHAR(50)     COMMENT 'Category: installation, maintenance, consulting',
    description         VARCHAR(500)    COMMENT 'Service description',
    is_active           BOOLEAN         COMMENT 'Whether service is currently active',
    created_at          TIMESTAMP_NTZ   COMMENT 'Record creation timestamp in source',
    updated_at          TIMESTAMP_NTZ   COMMENT 'Record last update timestamp in source'
)
COMMENT = 'Raw CDC data for NordHjem OLTP service offerings';

-- Invoices — billing invoices
CREATE OR REPLACE TABLE invoices (
    _op                 VARCHAR(10)     COMMENT 'CDC operation type',
    _source_ts          TIMESTAMP_NTZ   COMMENT 'Source system change timestamp',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _connector_batch_id VARCHAR(50)     COMMENT 'CDC connector batch identifier',
    invoice_id          INTEGER         COMMENT 'Natural key — invoice identifier',
    customer_id         INTEGER         COMMENT 'FK to customers',
    household_id        INTEGER         COMMENT 'FK to households',
    contract_id         INTEGER         COMMENT 'FK to contracts',
    invoice_date        DATE            COMMENT 'Invoice issue date',
    due_date            DATE            COMMENT 'Payment due date',
    total_amount        NUMBER(12,2)    COMMENT 'Total invoice amount including tax',
    tax_amount          NUMBER(12,2)    COMMENT 'Tax portion of total amount',
    status              VARCHAR(50)     COMMENT 'Status: issued, paid, overdue, cancelled',
    created_at          TIMESTAMP_NTZ   COMMENT 'Record creation timestamp in source',
    updated_at          TIMESTAMP_NTZ   COMMENT 'Record last update timestamp in source'
)
COMMENT = 'Raw CDC data for NordHjem OLTP invoices';

-- Invoice Line Items — individual line items on invoices
CREATE OR REPLACE TABLE invoice_line_items (
    _op                 VARCHAR(10)     COMMENT 'CDC operation type',
    _source_ts          TIMESTAMP_NTZ   COMMENT 'Source system change timestamp',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _connector_batch_id VARCHAR(50)     COMMENT 'CDC connector batch identifier',
    line_item_id        INTEGER         COMMENT 'Natural key — line item identifier',
    invoice_id          INTEGER         COMMENT 'FK to invoices',
    product_id          INTEGER         COMMENT 'FK to products',
    description         VARCHAR(500)    COMMENT 'Line item description',
    quantity            INTEGER         COMMENT 'Quantity',
    unit_price          NUMBER(12,2)    COMMENT 'Unit price',
    amount              NUMBER(12,2)    COMMENT 'Line item total amount',
    tax_amount          NUMBER(12,2)    COMMENT 'Tax amount for this line item',
    created_at          TIMESTAMP_NTZ   COMMENT 'Record creation timestamp in source',
    updated_at          TIMESTAMP_NTZ   COMMENT 'Record last update timestamp in source'
)
COMMENT = 'Raw CDC data for NordHjem OLTP invoice line items';

-- Payments — payment transactions
CREATE OR REPLACE TABLE payments (
    _op                 VARCHAR(10)     COMMENT 'CDC operation type',
    _source_ts          TIMESTAMP_NTZ   COMMENT 'Source system change timestamp',
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _connector_batch_id VARCHAR(50)     COMMENT 'CDC connector batch identifier',
    payment_id          INTEGER         COMMENT 'Natural key — payment identifier',
    invoice_id          INTEGER         COMMENT 'FK to invoices',
    customer_id         INTEGER         COMMENT 'FK to customers',
    payment_date        DATE            COMMENT 'Date payment was received',
    payment_amount      NUMBER(12,2)    COMMENT 'Payment amount',
    payment_method      VARCHAR(50)     COMMENT 'Method: card, bank_transfer, direct_debit',
    status              VARCHAR(50)     COMMENT 'Status: completed, pending, failed, refunded',
    created_at          TIMESTAMP_NTZ   COMMENT 'Record creation timestamp in source',
    updated_at          TIMESTAMP_NTZ   COMMENT 'Record last update timestamp in source'
)
COMMENT = 'Raw CDC data for NordHjem OLTP payment transactions';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. INSERT — Load seed data via INSERT INTO ... VALUES
-- ─────────────────────────────────────────────────────────────────────────────
-- Note: _loaded_at is excluded from column lists — it auto-populates via DEFAULT.

-- Customers
INSERT INTO customers (_op, _source_ts, _connector_batch_id, customer_id, email, first_name, last_name, phone, address, postal_code, municipality, region, country, segment, status, created_at, updated_at)
VALUES
    ('INSERT', '2025-01-05 09:12:33', 'batch_001', 1001, 'erik.lindberg@example.com', 'Erik', 'Lindberg', '+4520123456', 'Strandvejen 42', '2100', 'København Ø', 'Hovedstaden', 'DK', 'residential', 'active', '2025-01-05 09:12:33', '2025-01-05 09:12:33'),
    ('INSERT', '2025-01-05 09:14:01', 'batch_001', 1002, 'anna.svensson@example.com', 'Anna', 'Svensson', '+4687654321', 'Vasagatan 15', '11120', 'Stockholm', 'Stockholm', 'SE', 'residential', 'active', '2025-01-05 09:14:01', '2025-01-05 09:14:01'),
    ('INSERT', '2025-01-05 09:15:22', 'batch_001', 1003, 'lars.hansen@example.com', 'Lars', 'Hansen', '+4731234567', 'Bygdøy allé 8', '0257', 'Oslo', 'Oslo', 'NO', 'commercial', 'active', '2025-01-05 09:15:22', '2025-01-05 09:15:22'),
    ('INSERT', '2025-01-06 10:30:00', 'batch_002', 1004, 'mette.nielsen@example.com', 'Mette', 'Nielsen', '+4528765432', 'Algade 22', '4000', 'Roskilde', 'Sjælland', 'DK', 'residential', 'active', '2025-01-06 10:30:00', '2025-01-06 10:30:00'),
    ('INSERT', '2025-01-06 10:32:15', 'batch_002', 1005, 'olof.johansson@example.com', 'Olof', 'Johansson', '+46701234567', 'Kungsgatan 10', '41119', 'Göteborg', 'Västra Götaland', 'SE', 'commercial', 'active', '2025-01-06 10:32:15', '2025-01-06 10:32:15'),
    ('INSERT', '2025-01-07 08:45:00', 'batch_003', 1006, 'ingrid.berg@example.com', 'Ingrid', 'Berg', '+4790123456', 'Storgata 5', '0155', 'Oslo', 'Oslo', 'NO', 'residential', 'active', '2025-01-07 08:45:00', '2025-01-07 08:45:00'),
    ('INSERT', '2025-01-08 11:20:00', 'batch_004', 1007, 'karl.petersen@example.com', 'Karl', 'Petersen', '+4521987654', 'Vesterbrogade 100', '1620', 'København V', 'Hovedstaden', 'DK', 'residential', 'active', '2025-01-08 11:20:00', '2025-01-08 11:20:00'),
    ('INSERT', '2025-01-10 14:00:00', 'batch_005', 1008, 'sofia.nystrom@example.com', 'Sofia', 'Nyström', '+46739876543', 'Drottninggatan 55', '11121', 'Stockholm', 'Stockholm', 'SE', 'residential', 'active', '2025-01-10 14:00:00', '2025-01-10 14:00:00'),
    ('INSERT', '2025-01-12 09:00:00', 'batch_006', 1009, 'bjorn.dahl@example.com', 'Bjørn', 'Dahl', '+4741234567', 'Markveien 12', '0554', 'Oslo', 'Oslo', 'NO', 'commercial', 'active', '2025-01-12 09:00:00', '2025-01-12 09:00:00'),
    ('INSERT', '2025-01-15 16:30:00', 'batch_007', 1010, 'freya.madsen@example.com', 'Freya', 'Madsen', '+4523456789', 'Nørrebrogade 33', '2200', 'København N', 'Hovedstaden', 'DK', 'residential', 'active', '2025-01-15 16:30:00', '2025-01-15 16:30:00'),
    ('UPDATE', '2025-01-20 10:15:00', 'batch_008', 1001, 'erik.lindberg@example.com', 'Erik', 'Lindberg', '+4520123456', 'Strandvejen 42', '2100', 'København Ø', 'Hovedstaden', 'DK', 'premium', 'active', '2025-01-05 09:12:33', '2025-01-20 10:15:00'),
    ('UPDATE', '2025-01-25 14:30:00', 'batch_009', 1002, 'anna.svensson@newmail.se', 'Anna', 'Svensson', '+4687654321', 'Vasagatan 15', '11120', 'Stockholm', 'Stockholm', 'SE', 'residential', 'active', '2025-01-05 09:14:01', '2025-01-25 14:30:00'),
    ('UPDATE', '2025-02-01 09:00:00', 'batch_010', 1003, 'lars.hansen@example.com', 'Lars', 'Hansen', '+4731234567', 'Karl Johans gate 20', '0159', 'Oslo', 'Oslo', 'NO', 'commercial', 'active', '2025-01-05 09:15:22', '2025-02-01 09:00:00'),
    ('UPDATE', '2025-02-05 11:45:00', 'batch_011', 1004, 'mette.nielsen@example.com', 'Mette', 'Nielsen', '+4528765432', 'Algade 22', '4000', 'Roskilde', 'Sjælland', 'DK', 'premium', 'active', '2025-01-06 10:30:00', '2025-02-05 11:45:00'),
    ('UPDATE', '2025-02-10 08:30:00', 'batch_012', 1007, 'karl.petersen@example.com', 'Karl', 'Petersen', '+4521987654', 'Vesterbrogade 100', '1620', 'København V', 'Hovedstaden', 'DK', 'residential', 'churned', '2025-01-08 11:20:00', '2025-02-10 08:30:00'),
    ('UPDATE', '2025-02-15 13:00:00', 'batch_013', 1001, 'erik.lindberg@example.com', 'Erik', 'Lindberg', '+4520999888', 'Strandvejen 42', '2100', 'København Ø', 'Hovedstaden', 'DK', 'premium', 'active', '2025-01-05 09:12:33', '2025-02-15 13:00:00'),
    ('UPDATE', '2025-02-20 16:00:00', 'batch_014', 1005, 'olof.johansson@example.com', 'Olof', 'Johansson', '+46701234567', 'Kungsgatan 10', '41119', 'Göteborg', 'Västra Götaland', 'SE', 'premium', 'active', '2025-01-06 10:32:15', '2025-02-20 16:00:00'),
    ('UPDATE', '2025-02-28 10:00:00', 'batch_015', 1009, 'bjorn.dahl@example.com', 'Bjørn', 'Dahl', '+4741234567', 'Markveien 12', '0554', 'Oslo', 'Oslo', 'NO', 'commercial', 'inactive', '2025-01-12 09:00:00', '2025-02-28 10:00:00'),
    ('DELETE', '2025-03-05 09:00:00', 'batch_016', 1007, 'karl.petersen@example.com', 'Karl', 'Petersen', '+4521987654', 'Vesterbrogade 100', '1620', 'København V', 'Hovedstaden', 'DK', 'residential', 'churned', '2025-01-08 11:20:00', '2025-03-05 09:00:00'),
    ('UPDATE', '2025-03-10 12:00:00', 'batch_017', 1010, 'freya.madsen@example.com', 'Freya', 'Madsen', '+4523456789', 'Nørrebrogade 33', '2200', 'København N', 'Hovedstaden', 'DK', 'premium', 'active', '2025-01-15 16:30:00', '2025-03-10 12:00:00');

-- Households
INSERT INTO households (_op, _source_ts, _connector_batch_id, household_id, customer_id, address, postal_code, municipality, country, household_type, created_at, updated_at)
VALUES
    ('INSERT', '2025-01-05 09:20:00', 'batch_001', 2001, 1001, 'Strandvejen 42', '2100', 'København Ø', 'DK', 'apartment', '2025-01-05 09:20:00', '2025-01-05 09:20:00'),
    ('INSERT', '2025-01-05 09:22:00', 'batch_001', 2002, 1002, 'Vasagatan 15', '11120', 'Stockholm', 'SE', 'house', '2025-01-05 09:22:00', '2025-01-05 09:22:00'),
    ('INSERT', '2025-01-05 09:24:00', 'batch_001', 2003, 1003, 'Bygdøy allé 8', '0257', 'Oslo', 'NO', 'office', '2025-01-05 09:24:00', '2025-01-05 09:24:00'),
    ('INSERT', '2025-01-06 10:35:00', 'batch_002', 2004, 1004, 'Algade 22', '4000', 'Roskilde', 'DK', 'house', '2025-01-06 10:35:00', '2025-01-06 10:35:00'),
    ('INSERT', '2025-01-06 10:37:00', 'batch_002', 2005, 1005, 'Kungsgatan 10', '41119', 'Göteborg', 'SE', 'office', '2025-01-06 10:37:00', '2025-01-06 10:37:00'),
    ('INSERT', '2025-01-07 08:50:00', 'batch_003', 2006, 1006, 'Storgata 5', '0155', 'Oslo', 'NO', 'apartment', '2025-01-07 08:50:00', '2025-01-07 08:50:00'),
    ('INSERT', '2025-01-08 11:25:00', 'batch_004', 2007, 1007, 'Vesterbrogade 100', '1620', 'København V', 'DK', 'apartment', '2025-01-08 11:25:00', '2025-01-08 11:25:00'),
    ('INSERT', '2025-01-10 14:05:00', 'batch_005', 2008, 1008, 'Drottninggatan 55', '11121', 'Stockholm', 'SE', 'house', '2025-01-10 14:05:00', '2025-01-10 14:05:00'),
    ('INSERT', '2025-01-12 09:05:00', 'batch_006', 2009, 1009, 'Markveien 12', '0554', 'Oslo', 'NO', 'office', '2025-01-12 09:05:00', '2025-01-12 09:05:00'),
    ('INSERT', '2025-01-15 16:35:00', 'batch_007', 2010, 1010, 'Nørrebrogade 33', '2200', 'København N', 'DK', 'apartment', '2025-01-15 16:35:00', '2025-01-15 16:35:00'),
    ('INSERT', '2025-01-18 10:00:00', 'batch_008', 2011, 1001, 'Østerbrogade 88', '2100', 'København Ø', 'DK', 'house', '2025-01-18 10:00:00', '2025-01-18 10:00:00'),
    ('UPDATE', '2025-02-01 09:05:00', 'batch_010', 2003, 1003, 'Karl Johans gate 20', '0159', 'Oslo', 'NO', 'office', '2025-01-05 09:24:00', '2025-02-01 09:05:00'),
    ('UPDATE', '2025-02-10 11:00:00', 'batch_012', 2004, 1004, 'Algade 22', '4000', 'Roskilde', 'DK', 'apartment', '2025-01-06 10:35:00', '2025-02-10 11:00:00'),
    ('UPDATE', '2025-02-20 14:00:00', 'batch_014', 2005, 1005, 'Kungsgatan 10', '41119', 'Göteborg', 'SE', 'warehouse', '2025-01-06 10:37:00', '2025-02-20 14:00:00'),
    ('DELETE', '2025-03-05 09:05:00', 'batch_016', 2007, 1007, 'Vesterbrogade 100', '1620', 'København V', 'DK', 'apartment', '2025-01-08 11:25:00', '2025-03-05 09:05:00');

-- Installations
INSERT INTO installations (_op, _source_ts, _connector_batch_id, installation_id, household_id, installation_date, installer_partner_id, status, notes, created_at, updated_at)
VALUES
    ('INSERT', '2025-01-06 14:00:00', 'batch_002', 3001, 2001, '2025-01-10', 'P001', 'scheduled', 'Smart thermostat v2 installation', '2025-01-06 14:00:00', '2025-01-06 14:00:00'),
    ('INSERT', '2025-01-06 14:05:00', 'batch_002', 3002, 2002, '2025-01-12', 'P002', 'scheduled', 'Energy meter pro installation', '2025-01-06 14:05:00', '2025-01-06 14:05:00'),
    ('INSERT', '2025-01-07 09:00:00', 'batch_003', 3003, 2003, '2025-01-15', 'P001', 'scheduled', 'Full office energy monitoring setup', '2025-01-07 09:00:00', '2025-01-07 09:00:00'),
    ('INSERT', '2025-01-08 10:00:00', 'batch_004', 3004, 2004, '2025-01-18', 'P003', 'scheduled', 'Thermostat and meter bundle', '2025-01-08 10:00:00', '2025-01-08 10:00:00'),
    ('INSERT', '2025-01-10 11:00:00', 'batch_005', 3005, 2005, '2025-01-20', 'P002', 'scheduled', 'Commercial energy monitoring', '2025-01-10 11:00:00', '2025-01-10 11:00:00'),
    ('INSERT', '2025-01-12 13:00:00', 'batch_006', 3006, 2006, '2025-01-22', 'P001', 'scheduled', 'Smart thermostat installation', '2025-01-12 13:00:00', '2025-01-12 13:00:00'),
    ('INSERT', '2025-01-15 09:00:00', 'batch_007', 3007, 2008, '2025-01-25', 'P003', 'scheduled', 'Full home energy package', '2025-01-15 09:00:00', '2025-01-15 09:00:00'),
    ('INSERT', '2025-01-18 10:30:00', 'batch_008', 3008, 2009, '2025-01-28', 'P002', 'scheduled', 'Office meter installation', '2025-01-18 10:30:00', '2025-01-18 10:30:00'),
    ('INSERT', '2025-01-20 14:00:00', 'batch_008', 3009, 2010, '2025-02-01', 'P001', 'scheduled', 'Thermostat installation', '2025-01-20 14:00:00', '2025-01-20 14:00:00'),
    ('INSERT', '2025-01-22 09:00:00', 'batch_009', 3010, 2011, '2025-02-05', 'P003', 'scheduled', 'Second property setup', '2025-01-22 09:00:00', '2025-01-22 09:00:00'),
    ('UPDATE', '2025-01-10 16:00:00', 'batch_005', 3001, 2001, '2025-01-10', 'P001', 'completed', 'Smart thermostat v2 installed successfully', '2025-01-06 14:00:00', '2025-01-10 16:00:00'),
    ('UPDATE', '2025-01-12 17:00:00', 'batch_006', 3002, 2002, '2025-01-12', 'P002', 'completed', 'Energy meter pro installed and calibrated', '2025-01-06 14:05:00', '2025-01-12 17:00:00'),
    ('UPDATE', '2025-01-15 15:30:00', 'batch_007', 3003, 2003, '2025-01-15', 'P001', 'completed', 'Office setup complete — 3 devices', '2025-01-07 09:00:00', '2025-01-15 15:30:00'),
    ('UPDATE', '2025-01-18 14:00:00', 'batch_008', 3004, 2004, '2025-01-18', 'P003', 'completed', 'Bundle installed', '2025-01-08 10:00:00', '2025-01-18 14:00:00'),
    ('UPDATE', '2025-01-20 16:30:00', 'batch_008', 3005, 2005, '2025-01-20', 'P002', 'completed', 'Commercial monitoring active', '2025-01-10 11:00:00', '2025-01-20 16:30:00'),
    ('UPDATE', '2025-01-22 15:00:00', 'batch_009', 3006, 2006, '2025-01-22', 'P001', 'completed', 'Thermostat installed', '2025-01-12 13:00:00', '2025-01-22 15:00:00'),
    ('UPDATE', '2025-01-25 17:00:00', 'batch_009', 3007, 2008, '2025-01-25', 'P003', 'completed', 'Full package installed', '2025-01-15 09:00:00', '2025-01-25 17:00:00'),
    ('UPDATE', '2025-01-28 16:00:00', 'batch_010', 3008, 2009, '2025-01-28', 'P002', 'completed', 'Meter installed and verified', '2025-01-18 10:30:00', '2025-01-28 16:00:00'),
    ('UPDATE', '2025-02-01 15:00:00', 'batch_010', 3009, 2010, '2025-02-01', 'P001', 'completed', 'Thermostat installed', '2025-01-20 14:00:00', '2025-02-01 15:00:00'),
    ('UPDATE', '2025-02-05 14:00:00', 'batch_011', 3010, 2011, '2025-02-05', 'P003', 'completed', 'Second property setup done', '2025-01-22 09:00:00', '2025-02-05 14:00:00'),
    ('UPDATE', '2025-02-15 10:00:00', 'batch_013', 3003, 2003, '2025-01-15', 'P001', 'maintenance', 'Firmware update required on office devices', '2025-01-07 09:00:00', '2025-02-15 10:00:00'),
    ('DELETE', '2025-03-05 09:10:00', 'batch_016', 3009, 2010, '2025-02-01', 'P001', 'cancelled', 'Customer relocated — installation reversed', '2025-01-20 14:00:00', '2025-03-05 09:10:00');

-- Devices
INSERT INTO devices (_op, _source_ts, _connector_batch_id, device_id, device_serial, household_id, device_type, manufacturer, model, firmware_version, installed_at, status, created_at, updated_at)
VALUES
    ('INSERT', '2025-01-10 16:10:00', 'batch_005', 4001, 'NH-TH-20250110-001', 2001, 'thermostat', 'NordHjem', 'Smart Thermostat v2', '2.1.0', '2025-01-10', 'active', '2025-01-10 16:10:00', '2025-01-10 16:10:00'),
    ('INSERT', '2025-01-12 17:10:00', 'batch_006', 4002, 'NH-EM-20250112-001', 2002, 'energy_meter', 'NordHjem', 'Energy Meter Pro', '1.4.2', '2025-01-12', 'active', '2025-01-12 17:10:00', '2025-01-12 17:10:00'),
    ('INSERT', '2025-01-15 15:40:00', 'batch_007', 4003, 'NH-TH-20250115-001', 2003, 'thermostat', 'NordHjem', 'Smart Thermostat v2', '2.1.0', '2025-01-15', 'active', '2025-01-15 15:40:00', '2025-01-15 15:40:00'),
    ('INSERT', '2025-01-15 15:45:00', 'batch_007', 4004, 'NH-EM-20250115-001', 2003, 'energy_meter', 'NordHjem', 'Energy Meter Pro', '1.4.2', '2025-01-15', 'active', '2025-01-15 15:45:00', '2025-01-15 15:45:00'),
    ('INSERT', '2025-01-15 15:50:00', 'batch_007', 4005, 'NH-TS-20250115-001', 2003, 'temperature_sensor', 'NordHjem', 'Temp Sensor Mini', '1.0.3', '2025-01-15', 'active', '2025-01-15 15:50:00', '2025-01-15 15:50:00'),
    ('INSERT', '2025-01-18 14:10:00', 'batch_008', 4006, 'NH-TH-20250118-001', 2004, 'thermostat', 'NordHjem', 'Smart Thermostat v2', '2.1.0', '2025-01-18', 'active', '2025-01-18 14:10:00', '2025-01-18 14:10:00'),
    ('INSERT', '2025-01-18 14:15:00', 'batch_008', 4007, 'NH-EM-20250118-001', 2004, 'energy_meter', 'NordHjem', 'Energy Meter Pro', '1.4.2', '2025-01-18', 'active', '2025-01-18 14:15:00', '2025-01-18 14:15:00'),
    ('INSERT', '2025-01-20 16:40:00', 'batch_008', 4008, 'NH-EM-20250120-001', 2005, 'energy_meter', 'NordHjem', 'Energy Meter Pro', '1.4.2', '2025-01-20', 'active', '2025-01-20 16:40:00', '2025-01-20 16:40:00'),
    ('INSERT', '2025-01-22 15:10:00', 'batch_009', 4009, 'NH-TH-20250122-001', 2006, 'thermostat', 'NordHjem', 'Smart Thermostat v2', '2.1.0', '2025-01-22', 'active', '2025-01-22 15:10:00', '2025-01-22 15:10:00'),
    ('INSERT', '2025-01-25 17:10:00', 'batch_009', 4010, 'NH-TH-20250125-001', 2008, 'thermostat', 'NordHjem', 'Smart Thermostat v2', '2.1.0', '2025-01-25', 'active', '2025-01-25 17:10:00', '2025-01-25 17:10:00'),
    ('INSERT', '2025-01-25 17:15:00', 'batch_009', 4011, 'NH-EM-20250125-001', 2008, 'energy_meter', 'NordHjem', 'Energy Meter Pro', '1.4.2', '2025-01-25', 'active', '2025-01-25 17:15:00', '2025-01-25 17:15:00'),
    ('INSERT', '2025-01-28 16:10:00', 'batch_010', 4012, 'NH-EM-20250128-001', 2009, 'energy_meter', 'NordHjem', 'Energy Meter Pro', '1.4.2', '2025-01-28', 'active', '2025-01-28 16:10:00', '2025-01-28 16:10:00'),
    ('INSERT', '2025-02-01 15:10:00', 'batch_010', 4013, 'NH-TH-20250201-001', 2010, 'thermostat', 'NordHjem', 'Smart Thermostat v2', '2.1.0', '2025-02-01', 'active', '2025-02-01 15:10:00', '2025-02-01 15:10:00'),
    ('INSERT', '2025-02-05 14:10:00', 'batch_011', 4014, 'NH-TH-20250205-001', 2011, 'thermostat', 'NordHjem', 'Smart Thermostat v2', '2.1.0', '2025-02-05', 'active', '2025-02-05 14:10:00', '2025-02-05 14:10:00'),
    ('INSERT', '2025-02-05 14:15:00', 'batch_011', 4015, 'NH-EM-20250205-001', 2011, 'energy_meter', 'NordHjem', 'Energy Meter Pro', '1.4.2', '2025-02-05', 'active', '2025-02-05 14:15:00', '2025-02-05 14:15:00'),
    ('UPDATE', '2025-02-10 09:00:00', 'batch_012', 4003, 'NH-TH-20250115-001', 2003, 'thermostat', 'NordHjem', 'Smart Thermostat v2', '2.2.0', '2025-01-15', 'active', '2025-01-15 15:40:00', '2025-02-10 09:00:00'),
    ('UPDATE', '2025-02-10 09:05:00', 'batch_012', 4004, 'NH-EM-20250115-001', 2003, 'energy_meter', 'NordHjem', 'Energy Meter Pro', '1.5.0', '2025-01-15', 'active', '2025-01-15 15:45:00', '2025-02-10 09:05:00'),
    ('UPDATE', '2025-02-15 11:00:00', 'batch_013', 4001, 'NH-TH-20250110-001', 2001, 'thermostat', 'NordHjem', 'Smart Thermostat v2', '2.2.0', '2025-01-10', 'active', '2025-01-10 16:10:00', '2025-02-15 11:00:00'),
    ('UPDATE', '2025-02-20 10:00:00', 'batch_014', 4008, 'NH-EM-20250120-001', 2005, 'energy_meter', 'NordHjem', 'Energy Meter Pro', '1.5.0', '2025-01-20', 'degraded', '2025-01-20 16:40:00', '2025-02-20 10:00:00'),
    ('UPDATE', '2025-03-01 08:00:00', 'batch_015', 4008, 'NH-EM-20250120-001', 2005, 'energy_meter', 'NordHjem', 'Energy Meter Pro', '1.5.1', '2025-01-20', 'active', '2025-01-20 16:40:00', '2025-03-01 08:00:00'),
    ('DELETE', '2025-03-05 09:15:00', 'batch_016', 4013, 'NH-TH-20250201-001', 2010, 'thermostat', 'NordHjem', 'Smart Thermostat v2', '2.1.0', '2025-02-01', 'decommissioned', '2025-02-01 15:10:00', '2025-03-05 09:15:00');

-- Contracts
INSERT INTO contracts (_op, _source_ts, _connector_batch_id, contract_id, customer_id, household_id, product_id, tariff_plan_id, contract_type, status, start_date, end_date, monthly_amount, created_at, updated_at)
VALUES
    ('INSERT', '2025-01-05 10:00:00', 'batch_001', 6001, 1001, 2001, 7001, 5001, 'residential_energy', 'active', '2025-01-05', '2026-01-04', 349.00, '2025-01-05 10:00:00', '2025-01-05 10:00:00'),
    ('INSERT', '2025-01-05 10:05:00', 'batch_001', 6002, 1002, 2002, 7002, 5002, 'residential_energy', 'active', '2025-01-05', '2026-01-04', 299.00, '2025-01-05 10:05:00', '2025-01-05 10:05:00'),
    ('INSERT', '2025-01-05 10:10:00', 'batch_001', 6003, 1003, 2003, 7003, 5004, 'commercial_energy', 'active', '2025-01-05', '2026-01-04', 1499.00, '2025-01-05 10:10:00', '2025-01-05 10:10:00'),
    ('INSERT', '2025-01-06 11:00:00', 'batch_002', 6004, 1004, 2004, 7001, 5003, 'residential_energy', 'active', '2025-01-06', '2026-01-05', 399.00, '2025-01-06 11:00:00', '2025-01-06 11:00:00'),
    ('INSERT', '2025-01-06 11:05:00', 'batch_002', 6005, 1005, 2005, 7003, 5004, 'commercial_energy', 'active', '2025-01-06', '2026-01-05', 1299.00, '2025-01-06 11:05:00', '2025-01-06 11:05:00'),
    ('INSERT', '2025-01-07 09:30:00', 'batch_003', 6006, 1006, 2006, 7001, 5001, 'residential_energy', 'active', '2025-01-07', '2026-01-06', 349.00, '2025-01-07 09:30:00', '2025-01-07 09:30:00'),
    ('INSERT', '2025-01-08 12:00:00', 'batch_004', 6007, 1007, 2007, 7002, 5005, 'residential_energy', 'active', '2025-01-08', '2026-01-07', 449.00, '2025-01-08 12:00:00', '2025-01-08 12:00:00'),
    ('INSERT', '2025-01-10 15:00:00', 'batch_005', 6008, 1008, 2008, 7001, 5003, 'residential_energy', 'active', '2025-01-10', '2026-01-09', 399.00, '2025-01-10 15:00:00', '2025-01-10 15:00:00'),
    ('INSERT', '2025-01-12 10:00:00', 'batch_006', 6009, 1009, 2009, 7003, 5004, 'commercial_energy', 'active', '2025-01-12', '2026-01-11', 1499.00, '2025-01-12 10:00:00', '2025-01-12 10:00:00'),
    ('INSERT', '2025-01-15 17:00:00', 'batch_007', 6010, 1010, 2010, 7002, 5001, 'residential_energy', 'active', '2025-01-15', '2026-01-14', 349.00, '2025-01-15 17:00:00', '2025-01-15 17:00:00'),
    ('INSERT', '2025-01-18 10:30:00', 'batch_008', 6011, 1001, 2011, 7004, 5005, 'residential_energy', 'active', '2025-01-18', '2026-01-17', 449.00, '2025-01-18 10:30:00', '2025-01-18 10:30:00'),
    ('INSERT', '2025-01-20 09:00:00', 'batch_008', 6012, 1004, 2004, 7005, 5001, 'service_agreement', 'active', '2025-01-20', '2026-01-19', 99.00, '2025-01-20 09:00:00', '2025-01-20 09:00:00'),
    ('UPDATE', '2025-02-01 10:00:00', 'batch_010', 6003, 1003, 2003, 7003, 5004, 'commercial_energy', 'active', '2025-01-05', '2026-01-04', 1599.00, '2025-01-05 10:10:00', '2025-02-01 10:00:00'),
    ('UPDATE', '2025-02-10 09:00:00', 'batch_012', 6007, 1007, 2007, 7002, 5005, 'residential_energy', 'cancelled', '2025-01-08', '2025-02-10', 449.00, '2025-01-08 12:00:00', '2025-02-10 09:00:00'),
    ('UPDATE', '2025-02-15 14:00:00', 'batch_013', 6001, 1001, 2001, 7001, 5005, 'residential_energy', 'active', '2025-01-05', '2026-01-04', 449.00, '2025-01-05 10:00:00', '2025-02-15 14:00:00'),
    ('UPDATE', '2025-02-20 16:30:00', 'batch_014', 6005, 1005, 2005, 7003, 5004, 'commercial_energy', 'renewed', '2025-01-06', '2027-01-05', 1399.00, '2025-01-06 11:05:00', '2025-02-20 16:30:00'),
    ('UPDATE', '2025-02-28 10:30:00', 'batch_015', 6009, 1009, 2009, 7003, 5004, 'commercial_energy', 'suspended', '2025-01-12', '2026-01-11', 1499.00, '2025-01-12 10:00:00', '2025-02-28 10:30:00'),
    ('DELETE', '2025-03-05 09:20:00', 'batch_016', 6007, 1007, 2007, 7002, 5005, 'residential_energy', 'cancelled', '2025-01-08', '2025-02-10', 449.00, '2025-01-08 12:00:00', '2025-03-05 09:20:00'),
    ('UPDATE', '2025-03-10 12:30:00', 'batch_017', 6010, 1010, 2010, 7002, 5005, 'residential_energy', 'active', '2025-01-15', '2026-01-14', 449.00, '2025-01-15 17:00:00', '2025-03-10 12:30:00');

-- Tariff Plans
INSERT INTO tariff_plans (_op, _source_ts, _connector_batch_id, tariff_plan_id, plan_name, plan_type, price_per_kwh, monthly_base_fee, valid_from, valid_to, created_at, updated_at)
VALUES
    ('INSERT', '2025-01-02 08:00:00', 'batch_001', 5001, 'NordBasis Fastpris', 'fixed', 0.85, 149.00, '2025-01-01', '2025-12-31', '2025-01-02 08:00:00', '2025-01-02 08:00:00'),
    ('INSERT', '2025-01-02 08:05:00', 'batch_001', 5002, 'NordFlex Spotpris', 'variable', 0.00, 99.00, '2025-01-01', '2025-12-31', '2025-01-02 08:05:00', '2025-01-02 08:05:00'),
    ('INSERT', '2025-01-02 08:10:00', 'batch_001', 5003, 'NordGrøn Bæredygtig', 'green', 0.95, 199.00, '2025-01-01', '2025-12-31', '2025-01-02 08:10:00', '2025-01-02 08:10:00'),
    ('INSERT', '2025-01-02 08:15:00', 'batch_001', 5004, 'NordErhverv Business', 'commercial', 0.72, 499.00, '2025-01-01', '2025-12-31', '2025-01-02 08:15:00', '2025-01-02 08:15:00'),
    ('INSERT', '2025-01-02 08:20:00', 'batch_001', 5005, 'NordPremium Alt-Inkl', 'premium', 1.10, 349.00, '2025-01-01', '2025-12-31', '2025-01-02 08:20:00', '2025-01-02 08:20:00'),
    ('UPDATE', '2025-02-01 07:00:00', 'batch_010', 5002, 'NordFlex Spotpris', 'variable', 0.00, 109.00, '2025-01-01', '2025-12-31', '2025-01-02 08:05:00', '2025-02-01 07:00:00'),
    ('UPDATE', '2025-02-15 07:00:00', 'batch_013', 5001, 'NordBasis Fastpris', 'fixed', 0.89, 149.00, '2025-01-01', '2025-12-31', '2025-01-02 08:00:00', '2025-02-15 07:00:00'),
    ('UPDATE', '2025-03-01 07:00:00', 'batch_015', 5004, 'NordErhverv Business', 'commercial', 0.75, 499.00, '2025-01-01', '2025-12-31', '2025-01-02 08:15:00', '2025-03-01 07:00:00');

-- Products
INSERT INTO products (_op, _source_ts, _connector_batch_id, product_id, product_name, category, description, pricing_tier, is_active, created_at, updated_at)
VALUES
    ('INSERT', '2025-01-02 07:00:00', 'batch_001', 7001, 'Smart Thermostat v2', 'device', 'Intelligent thermostat with learning algorithms and remote control', 'standard', TRUE, '2025-01-02 07:00:00', '2025-01-02 07:00:00'),
    ('INSERT', '2025-01-02 07:05:00', 'batch_001', 7002, 'Energy Meter Pro', 'device', 'Real-time energy consumption monitoring with grid feedback', 'standard', TRUE, '2025-01-02 07:05:00', '2025-01-02 07:05:00'),
    ('INSERT', '2025-01-02 07:10:00', 'batch_001', 7003, 'Commercial Energy Suite', 'bundle', 'Full commercial energy monitoring and optimization package', 'premium', TRUE, '2025-01-02 07:10:00', '2025-01-02 07:10:00'),
    ('INSERT', '2025-01-02 07:15:00', 'batch_001', 7004, 'Home Energy Package', 'bundle', 'Thermostat + meter + temperature sensor bundle for homes', 'standard', TRUE, '2025-01-02 07:15:00', '2025-01-02 07:15:00'),
    ('INSERT', '2025-01-02 07:20:00', 'batch_001', 7005, 'Annual Service Plan', 'service', 'Annual maintenance and support for all installed devices', 'basic', TRUE, '2025-01-02 07:20:00', '2025-01-02 07:20:00'),
    ('INSERT', '2025-01-02 07:25:00', 'batch_001', 7006, 'Temp Sensor Mini', 'device', 'Compact temperature and humidity sensor for room monitoring', 'basic', TRUE, '2025-01-02 07:25:00', '2025-01-02 07:25:00'),
    ('INSERT', '2025-01-02 07:30:00', 'batch_001', 7007, 'Sustainability Advisory', 'service', 'Quarterly energy optimization consultation and reporting', 'premium', TRUE, '2025-01-02 07:30:00', '2025-01-02 07:30:00'),
    ('INSERT', '2025-01-02 07:35:00', 'batch_001', 7008, 'Solar Integration Kit', 'device', 'Solar panel monitoring and grid export optimization module', 'premium', TRUE, '2025-01-02 07:35:00', '2025-01-02 07:35:00'),
    ('UPDATE', '2025-02-01 08:00:00', 'batch_010', 7001, 'Smart Thermostat v2', 'device', 'Intelligent thermostat with learning algorithms and remote control via app', 'standard', TRUE, '2025-01-02 07:00:00', '2025-02-01 08:00:00'),
    ('UPDATE', '2025-02-15 08:00:00', 'batch_013', 7003, 'Commercial Energy Suite', 'bundle', 'Full commercial energy monitoring optimization and reporting package', 'premium', TRUE, '2025-01-02 07:10:00', '2025-02-15 08:00:00'),
    ('UPDATE', '2025-03-01 08:00:00', 'batch_015', 7008, 'Solar Integration Kit', 'device', 'Solar panel monitoring and grid export optimization module', 'premium', FALSE, '2025-01-02 07:35:00', '2025-03-01 08:00:00');

-- Services
INSERT INTO services (_op, _source_ts, _connector_batch_id, service_id, service_name, category, description, is_active, created_at, updated_at)
VALUES
    ('INSERT', '2025-01-02 07:40:00', 'batch_001', 8001, 'Device Installation', 'installation', 'On-site installation of smart home devices by certified technician', TRUE, '2025-01-02 07:40:00', '2025-01-02 07:40:00'),
    ('INSERT', '2025-01-02 07:45:00', 'batch_001', 8002, 'Firmware Update', 'maintenance', 'Remote or on-site firmware update for all NordHjem devices', TRUE, '2025-01-02 07:45:00', '2025-01-02 07:45:00'),
    ('INSERT', '2025-01-02 07:50:00', 'batch_001', 8003, 'Device Replacement', 'maintenance', 'Replacement of faulty devices under warranty or service plan', TRUE, '2025-01-02 07:50:00', '2025-01-02 07:50:00'),
    ('INSERT', '2025-01-02 07:55:00', 'batch_001', 8004, 'Energy Audit', 'consulting', 'Comprehensive home or office energy efficiency assessment', TRUE, '2025-01-02 07:55:00', '2025-01-02 07:55:00'),
    ('INSERT', '2025-01-02 08:00:00', 'batch_001', 8005, 'Technical Support', 'support', 'Remote technical support via phone or chat', TRUE, '2025-01-02 08:00:00', '2025-01-02 08:00:00'),
    ('INSERT', '2025-01-02 08:05:00', 'batch_001', 8006, 'System Decommission', 'installation', 'Safe removal and recycling of installed devices', TRUE, '2025-01-02 08:05:00', '2025-01-02 08:05:00'),
    ('UPDATE', '2025-02-01 08:10:00', 'batch_010', 8004, 'Energy Audit', 'consulting', 'Comprehensive home or office energy efficiency assessment with sustainability report', TRUE, '2025-01-02 07:55:00', '2025-02-01 08:10:00'),
    ('UPDATE', '2025-03-01 08:10:00', 'batch_015', 8006, 'System Decommission', 'installation', 'Safe removal and recycling of installed devices', FALSE, '2025-01-02 08:05:00', '2025-03-01 08:10:00'),
    ('DELETE', '2025-03-10 08:00:00', 'batch_017', 8006, 'System Decommission', 'installation', 'Safe removal and recycling of installed devices', FALSE, '2025-01-02 08:05:00', '2025-03-10 08:00:00');

-- Invoices
INSERT INTO invoices (_op, _source_ts, _connector_batch_id, invoice_id, customer_id, household_id, contract_id, invoice_date, due_date, total_amount, tax_amount, status, created_at, updated_at)
VALUES
    ('INSERT', '2025-02-01 06:00:00', 'batch_010', 9001, 1001, 2001, 6001, '2025-02-01', '2025-02-28', 436.25, 87.25, 'issued', '2025-02-01 06:00:00', '2025-02-01 06:00:00'),
    ('INSERT', '2025-02-01 06:05:00', 'batch_010', 9002, 1002, 2002, 6002, '2025-02-01', '2025-02-28', 373.75, 74.75, 'issued', '2025-02-01 06:05:00', '2025-02-01 06:05:00'),
    ('INSERT', '2025-02-01 06:10:00', 'batch_010', 9003, 1003, 2003, 6003, '2025-02-01', '2025-02-28', 1873.75, 374.75, 'issued', '2025-02-01 06:10:00', '2025-02-01 06:10:00'),
    ('INSERT', '2025-02-01 06:15:00', 'batch_010', 9004, 1004, 2004, 6004, '2025-02-01', '2025-02-28', 498.75, 99.75, 'issued', '2025-02-01 06:15:00', '2025-02-01 06:15:00'),
    ('INSERT', '2025-02-01 06:20:00', 'batch_010', 9005, 1005, 2005, 6005, '2025-02-01', '2025-02-28', 1623.75, 324.75, 'issued', '2025-02-01 06:20:00', '2025-02-01 06:20:00'),
    ('INSERT', '2025-02-01 06:25:00', 'batch_010', 9006, 1006, 2006, 6006, '2025-02-01', '2025-02-28', 436.25, 87.25, 'issued', '2025-02-01 06:25:00', '2025-02-01 06:25:00'),
    ('INSERT', '2025-02-01 06:30:00', 'batch_010', 9007, 1007, 2007, 6007, '2025-02-01', '2025-02-28', 561.25, 112.25, 'issued', '2025-02-01 06:30:00', '2025-02-01 06:30:00'),
    ('INSERT', '2025-02-01 06:35:00', 'batch_010', 9008, 1008, 2008, 6008, '2025-02-01', '2025-02-28', 498.75, 99.75, 'issued', '2025-02-01 06:35:00', '2025-02-01 06:35:00'),
    ('INSERT', '2025-02-01 06:40:00', 'batch_010', 9009, 1009, 2009, 6009, '2025-02-01', '2025-02-28', 1873.75, 374.75, 'issued', '2025-02-01 06:40:00', '2025-02-01 06:40:00'),
    ('INSERT', '2025-02-01 06:45:00', 'batch_010', 9010, 1010, 2010, 6010, '2025-02-01', '2025-02-28', 436.25, 87.25, 'issued', '2025-02-01 06:45:00', '2025-02-01 06:45:00'),
    ('INSERT', '2025-02-01 06:50:00', 'batch_010', 9011, 1001, 2011, 6011, '2025-02-01', '2025-02-28', 561.25, 112.25, 'issued', '2025-02-01 06:50:00', '2025-02-01 06:50:00'),
    ('INSERT', '2025-02-01 06:55:00', 'batch_010', 9012, 1004, 2004, 6012, '2025-02-01', '2025-02-28', 123.75, 24.75, 'issued', '2025-02-01 06:55:00', '2025-02-01 06:55:00'),
    ('INSERT', '2025-03-01 06:00:00', 'batch_015', 9013, 1001, 2001, 6001, '2025-03-01', '2025-03-31', 561.25, 112.25, 'issued', '2025-03-01 06:00:00', '2025-03-01 06:00:00'),
    ('INSERT', '2025-03-01 06:05:00', 'batch_015', 9014, 1002, 2002, 6002, '2025-03-01', '2025-03-31', 373.75, 74.75, 'issued', '2025-03-01 06:05:00', '2025-03-01 06:05:00'),
    ('INSERT', '2025-03-01 06:10:00', 'batch_015', 9015, 1003, 2003, 6003, '2025-03-01', '2025-03-31', 1998.75, 399.75, 'issued', '2025-03-01 06:10:00', '2025-03-01 06:10:00'),
    ('UPDATE', '2025-02-15 10:00:00', 'batch_013', 9001, 1001, 2001, 6001, '2025-02-01', '2025-02-28', 436.25, 87.25, 'paid', '2025-02-01 06:00:00', '2025-02-15 10:00:00'),
    ('UPDATE', '2025-02-18 09:00:00', 'batch_013', 9002, 1002, 2002, 6002, '2025-02-01', '2025-02-28', 373.75, 74.75, 'paid', '2025-02-01 06:05:00', '2025-02-18 09:00:00'),
    ('UPDATE', '2025-02-20 14:00:00', 'batch_014', 9003, 1003, 2003, 6003, '2025-02-01', '2025-02-28', 1873.75, 374.75, 'paid', '2025-02-01 06:10:00', '2025-02-20 14:00:00'),
    ('UPDATE', '2025-02-25 11:00:00', 'batch_014', 9004, 1004, 2004, 6004, '2025-02-01', '2025-02-28', 498.75, 99.75, 'paid', '2025-02-01 06:15:00', '2025-02-25 11:00:00'),
    ('UPDATE', '2025-02-28 16:00:00', 'batch_015', 9005, 1005, 2005, 6005, '2025-02-01', '2025-02-28', 1623.75, 324.75, 'paid', '2025-02-01 06:20:00', '2025-02-28 16:00:00'),
    ('UPDATE', '2025-03-05 10:00:00', 'batch_016', 9007, 1007, 2007, 6007, '2025-02-01', '2025-02-28', 561.25, 112.25, 'overdue', '2025-02-01 06:30:00', '2025-03-05 10:00:00'),
    ('UPDATE', '2025-03-10 09:00:00', 'batch_017', 9009, 1009, 2009, 6009, '2025-02-01', '2025-02-28', 1873.75, 374.75, 'overdue', '2025-02-01 06:40:00', '2025-03-10 09:00:00'),
    ('DELETE', '2025-03-10 09:30:00', 'batch_017', 9007, 1007, 2007, 6007, '2025-02-01', '2025-02-28', 561.25, 112.25, 'voided', '2025-02-01 06:30:00', '2025-03-10 09:30:00');

-- Invoice Line Items
INSERT INTO invoice_line_items (_op, _source_ts, _connector_batch_id, line_item_id, invoice_id, product_id, description, quantity, unit_price, amount, tax_amount, created_at, updated_at)
VALUES
    ('INSERT', '2025-02-01 06:00:00', 'batch_010', 10001, 9001, 7001, 'Smart Thermostat v2 — monthly subscription', 1, 349.00, 349.00, 87.25, '2025-02-01 06:00:00', '2025-02-01 06:00:00'),
    ('INSERT', '2025-02-01 06:05:00', 'batch_010', 10002, 9002, 7002, 'Energy Meter Pro — monthly subscription', 1, 299.00, 299.00, 74.75, '2025-02-01 06:05:00', '2025-02-01 06:05:00'),
    ('INSERT', '2025-02-01 06:10:00', 'batch_010', 10003, 9003, 7003, 'Commercial Energy Suite — monthly subscription', 1, 1499.00, 1499.00, 374.75, '2025-02-01 06:10:00', '2025-02-01 06:10:00'),
    ('INSERT', '2025-02-01 06:15:00', 'batch_010', 10004, 9004, 7001, 'Smart Thermostat v2 — monthly subscription', 1, 399.00, 399.00, 99.75, '2025-02-01 06:15:00', '2025-02-01 06:15:00'),
    ('INSERT', '2025-02-01 06:20:00', 'batch_010', 10005, 9005, 7003, 'Commercial Energy Suite — monthly subscription', 1, 1299.00, 1299.00, 324.75, '2025-02-01 06:20:00', '2025-02-01 06:20:00'),
    ('INSERT', '2025-02-01 06:25:00', 'batch_010', 10006, 9006, 7001, 'Smart Thermostat v2 — monthly subscription', 1, 349.00, 349.00, 87.25, '2025-02-01 06:25:00', '2025-02-01 06:25:00'),
    ('INSERT', '2025-02-01 06:30:00', 'batch_010', 10007, 9007, 7002, 'Energy Meter Pro — monthly subscription', 1, 449.00, 449.00, 112.25, '2025-02-01 06:30:00', '2025-02-01 06:30:00'),
    ('INSERT', '2025-02-01 06:35:00', 'batch_010', 10008, 9008, 7001, 'Smart Thermostat v2 — monthly subscription', 1, 399.00, 399.00, 99.75, '2025-02-01 06:35:00', '2025-02-01 06:35:00'),
    ('INSERT', '2025-02-01 06:40:00', 'batch_010', 10009, 9009, 7003, 'Commercial Energy Suite — monthly subscription', 1, 1499.00, 1499.00, 374.75, '2025-02-01 06:40:00', '2025-02-01 06:40:00'),
    ('INSERT', '2025-02-01 06:45:00', 'batch_010', 10010, 9010, 7002, 'Energy Meter Pro — monthly subscription', 1, 349.00, 349.00, 87.25, '2025-02-01 06:45:00', '2025-02-01 06:45:00'),
    ('INSERT', '2025-02-01 06:50:00', 'batch_010', 10011, 9011, 7004, 'Home Energy Package — monthly subscription', 1, 449.00, 449.00, 112.25, '2025-02-01 06:50:00', '2025-02-01 06:50:00'),
    ('INSERT', '2025-02-01 06:55:00', 'batch_010', 10012, 9012, 7005, 'Annual Service Plan — monthly subscription', 1, 99.00, 99.00, 24.75, '2025-02-01 06:55:00', '2025-02-01 06:55:00'),
    ('INSERT', '2025-03-01 06:00:00', 'batch_015', 10013, 9013, 7001, 'Smart Thermostat v2 — monthly subscription', 1, 449.00, 449.00, 112.25, '2025-03-01 06:00:00', '2025-03-01 06:00:00'),
    ('INSERT', '2025-03-01 06:05:00', 'batch_015', 10014, 9014, 7002, 'Energy Meter Pro — monthly subscription', 1, 299.00, 299.00, 74.75, '2025-03-01 06:05:00', '2025-03-01 06:05:00'),
    ('INSERT', '2025-03-01 06:10:00', 'batch_015', 10015, 9015, 7003, 'Commercial Energy Suite — monthly subscription', 1, 1599.00, 1599.00, 399.75, '2025-03-01 06:10:00', '2025-03-01 06:10:00'),
    ('INSERT', '2025-02-01 06:00:10', 'batch_010', 10016, 9001, 7005, 'Annual Service Plan — pro-rated', 1, 0.00, 0.00, 0.00, '2025-02-01 06:00:10', '2025-02-01 06:00:10'),
    ('INSERT', '2025-02-01 06:10:10', 'batch_010', 10017, 9003, 7007, 'Sustainability Advisory — quarterly', 1, 0.00, 0.00, 0.00, '2025-02-01 06:10:10', '2025-02-01 06:10:10'),
    ('INSERT', '2025-02-01 06:20:10', 'batch_010', 10018, 9005, 7007, 'Sustainability Advisory — quarterly', 1, 0.00, 0.00, 0.00, '2025-02-01 06:20:10', '2025-02-01 06:20:10'),
    ('UPDATE', '2025-02-15 10:05:00', 'batch_013', 10001, 9001, 7001, 'Smart Thermostat v2 — monthly subscription', 1, 349.00, 349.00, 87.25, '2025-02-01 06:00:00', '2025-02-15 10:05:00'),
    ('UPDATE', '2025-02-18 09:05:00', 'batch_013', 10002, 9002, 7002, 'Energy Meter Pro — monthly subscription', 1, 299.00, 299.00, 74.75, '2025-02-01 06:05:00', '2025-02-18 09:05:00'),
    ('DELETE', '2025-03-10 09:35:00', 'batch_017', 10007, 9007, 7002, 'Energy Meter Pro — monthly subscription', 1, 449.00, 449.00, 112.25, '2025-02-01 06:30:00', '2025-03-10 09:35:00');

-- Payments
INSERT INTO payments (_op, _source_ts, _connector_batch_id, payment_id, invoice_id, customer_id, payment_date, payment_amount, payment_method, status, created_at, updated_at)
VALUES
    ('INSERT', '2025-02-15 10:00:00', 'batch_013', 11001, 9001, 1001, '2025-02-15', 436.25, 'card', 'completed', '2025-02-15 10:00:00', '2025-02-15 10:00:00'),
    ('INSERT', '2025-02-18 09:00:00', 'batch_013', 11002, 9002, 1002, '2025-02-18', 373.75, 'bank_transfer', 'completed', '2025-02-18 09:00:00', '2025-02-18 09:00:00'),
    ('INSERT', '2025-02-20 14:00:00', 'batch_014', 11003, 9003, 1003, '2025-02-20', 1873.75, 'bank_transfer', 'completed', '2025-02-20 14:00:00', '2025-02-20 14:00:00'),
    ('INSERT', '2025-02-25 11:00:00', 'batch_014', 11004, 9004, 1004, '2025-02-25', 498.75, 'card', 'completed', '2025-02-25 11:00:00', '2025-02-25 11:00:00'),
    ('INSERT', '2025-02-28 16:00:00', 'batch_015', 11005, 9005, 1005, '2025-02-28', 1623.75, 'bank_transfer', 'completed', '2025-02-28 16:00:00', '2025-02-28 16:00:00'),
    ('INSERT', '2025-02-20 09:00:00', 'batch_014', 11006, 9006, 1006, '2025-02-20', 436.25, 'mobilepay', 'completed', '2025-02-20 09:00:00', '2025-02-20 09:00:00'),
    ('INSERT', '2025-02-22 10:00:00', 'batch_014', 11007, 9008, 1008, '2025-02-22', 498.75, 'card', 'completed', '2025-02-22 10:00:00', '2025-02-22 10:00:00'),
    ('INSERT', '2025-02-25 14:00:00', 'batch_014', 11008, 9010, 1010, '2025-02-25', 436.25, 'mobilepay', 'completed', '2025-02-25 14:00:00', '2025-02-25 14:00:00'),
    ('INSERT', '2025-02-26 09:00:00', 'batch_015', 11009, 9011, 1001, '2025-02-26', 561.25, 'card', 'completed', '2025-02-26 09:00:00', '2025-02-26 09:00:00'),
    ('INSERT', '2025-02-27 11:00:00', 'batch_015', 11010, 9012, 1004, '2025-02-27', 123.75, 'card', 'completed', '2025-02-27 11:00:00', '2025-02-27 11:00:00'),
    ('INSERT', '2025-03-05 15:00:00', 'batch_016', 11011, 9007, 1007, '2025-03-05', 200.00, 'card', 'partial', '2025-03-05 15:00:00', '2025-03-05 15:00:00'),
    ('INSERT', '2025-03-15 10:00:00', 'batch_017', 11012, 9013, 1001, '2025-03-15', 561.25, 'card', 'completed', '2025-03-15 10:00:00', '2025-03-15 10:00:00'),
    ('INSERT', '2025-03-16 09:00:00', 'batch_017', 11013, 9014, 1002, '2025-03-16', 373.75, 'bank_transfer', 'completed', '2025-03-16 09:00:00', '2025-03-16 09:00:00'),
    ('UPDATE', '2025-03-06 10:00:00', 'batch_016', 11011, 9007, 1007, '2025-03-05', 200.00, 'card', 'refunded', '2025-03-05 15:00:00', '2025-03-06 10:00:00'),
    ('UPDATE', '2025-03-10 10:00:00', 'batch_017', 11011, 9007, 1007, '2025-03-05', 200.00, 'card', 'voided', '2025-03-05 15:00:00', '2025-03-10 10:00:00'),
    ('DELETE', '2025-03-10 10:05:00', 'batch_017', 11011, 9007, 1007, '2025-03-05', 200.00, 'card', 'voided', '2025-03-05 15:00:00', '2025-03-10 10:05:00');



