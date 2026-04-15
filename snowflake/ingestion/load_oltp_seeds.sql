-- =============================================================================
-- load_oltp_seeds.sql — Create raw OLTP tables and load CDC seed data
-- =============================================================================
-- Purpose:  Creates raw tables in RAW.OLTP for all 11 OLTP entities with CDC
--           metadata columns, then loads synthetic seed CSVs via PUT + COPY INTO.
--
-- Prerequisites:
--   - 01_databases.sql  (LIGHTHOUSE_{ENV}_RAW database)
--   - 05_schemas.sql    (RAW.OLTP schema)
--   - 06_stages.sql     (@RAW.OLTP.oltp_stage)
--   - 08_file_formats.sql (RAW.OLTP.csv_format)
--
-- CDC metadata columns:
--   _op                 — Change operation (INSERT, UPDATE, DELETE)
--   _source_ts          — Source system timestamp of the change
--   _loaded_at          — Platform ingestion timestamp (auto-populated)
--   _connector_batch_id — CDC connector batch identifier
--
-- Idempotency: Uses CREATE OR REPLACE TABLE — safe to re-run.
-- =============================================================================

USE WAREHOUSE INGESTION_WH;
USE DATABASE LIGHTHOUSE_DEV_RAW;
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
-- 2. PUT — Upload seed CSV files to internal stage
-- ─────────────────────────────────────────────────────────────────────────────

PUT file://data/oltp/customers.csv         @oltp_stage/customers/         AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/oltp/households.csv        @oltp_stage/households/        AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/oltp/installations.csv     @oltp_stage/installations/     AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/oltp/devices.csv           @oltp_stage/devices/           AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/oltp/contracts.csv         @oltp_stage/contracts/         AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/oltp/tariff_plans.csv      @oltp_stage/tariff_plans/      AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/oltp/products.csv          @oltp_stage/products/          AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/oltp/services.csv          @oltp_stage/services/          AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/oltp/invoices.csv          @oltp_stage/invoices/          AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/oltp/invoice_line_items.csv @oltp_stage/invoice_line_items/ AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/oltp/payments.csv          @oltp_stage/payments/          AUTO_COMPRESS = TRUE OVERWRITE = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. COPY INTO — Load seed data from stage into raw tables
-- ─────────────────────────────────────────────────────────────────────────────
-- Note: _loaded_at is excluded from column lists — it auto-populates via DEFAULT.

COPY INTO customers (_op, _source_ts, _connector_batch_id, customer_id, email, first_name, last_name, phone, address, postal_code, municipality, region, country, segment, status, created_at, updated_at)
    FROM @oltp_stage/customers/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO households (_op, _source_ts, _connector_batch_id, household_id, customer_id, address, postal_code, municipality, country, household_type, created_at, updated_at)
    FROM @oltp_stage/households/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO installations (_op, _source_ts, _connector_batch_id, installation_id, household_id, installation_date, installer_partner_id, status, notes, created_at, updated_at)
    FROM @oltp_stage/installations/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO devices (_op, _source_ts, _connector_batch_id, device_id, device_serial, household_id, device_type, manufacturer, model, firmware_version, installed_at, status, created_at, updated_at)
    FROM @oltp_stage/devices/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO contracts (_op, _source_ts, _connector_batch_id, contract_id, customer_id, household_id, product_id, tariff_plan_id, contract_type, status, start_date, end_date, monthly_amount, created_at, updated_at)
    FROM @oltp_stage/contracts/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO tariff_plans (_op, _source_ts, _connector_batch_id, tariff_plan_id, plan_name, plan_type, price_per_kwh, monthly_base_fee, valid_from, valid_to, created_at, updated_at)
    FROM @oltp_stage/tariff_plans/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO products (_op, _source_ts, _connector_batch_id, product_id, product_name, category, description, pricing_tier, is_active, created_at, updated_at)
    FROM @oltp_stage/products/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO services (_op, _source_ts, _connector_batch_id, service_id, service_name, category, description, is_active, created_at, updated_at)
    FROM @oltp_stage/services/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO invoices (_op, _source_ts, _connector_batch_id, invoice_id, customer_id, household_id, contract_id, invoice_date, due_date, total_amount, tax_amount, status, created_at, updated_at)
    FROM @oltp_stage/invoices/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO invoice_line_items (_op, _source_ts, _connector_batch_id, line_item_id, invoice_id, product_id, description, quantity, unit_price, amount, tax_amount, created_at, updated_at)
    FROM @oltp_stage/invoice_line_items/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO payments (_op, _source_ts, _connector_batch_id, payment_id, invoice_id, customer_id, payment_date, payment_amount, payment_method, status, created_at, updated_at)
    FROM @oltp_stage/payments/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';
