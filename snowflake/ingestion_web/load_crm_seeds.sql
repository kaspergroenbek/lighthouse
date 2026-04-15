-- =============================================================================
-- load_crm_seeds.sql — Snowsight-compatible version (INSERT INTO ... VALUES)
-- =============================================================================
-- Purpose:  Creates raw tables in RAW.CRM for all 8 CRM objects with SaaS
--           connector metadata columns, then loads synthetic seed data via
--           INSERT INTO ... VALUES.
--           This version runs in Snowflake's web UI (Snowsight) without SnowSQL.
--
-- Original: lighthouse/snowflake/ingestion/load_crm_seeds.sql (PUT + COPY INTO)
--
-- SaaS connector metadata columns:
--   _loaded_at   — Platform ingestion timestamp (included in data for CRM)
--   _sync_id     — Connector sync batch identifier
--   _is_deleted  — Soft-delete flag from SaaS source
--
-- Idempotency: Uses CREATE OR REPLACE TABLE — safe to re-run.
-- =============================================================================

SET LIGHTHOUSE_ENV = 'DEV';
SET LIGHTHOUSE_RAW_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_RAW';

USE WAREHOUSE INGESTION_WH;
EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_RAW_DB;
USE SCHEMA CRM;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. RAW TABLE DDL
-- ─────────────────────────────────────────────────────────────────────────────

-- Accounts — CRM account records (households and businesses)
CREATE OR REPLACE TABLE accounts (
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _sync_id            VARCHAR(50)     COMMENT 'SaaS connector sync batch identifier',
    _is_deleted         BOOLEAN         DEFAULT FALSE COMMENT 'Soft-delete flag from CRM',
    account_id          VARCHAR(50)     COMMENT 'Natural key — CRM account identifier',
    account_name        VARCHAR(255)    COMMENT 'Account display name',
    industry            VARCHAR(100)    COMMENT 'Industry classification',
    website             VARCHAR(500)    COMMENT 'Account website URL',
    phone               VARCHAR(50)     COMMENT 'Account phone number',
    billing_address     VARCHAR(500)    COMMENT 'Billing address',
    region              VARCHAR(100)    COMMENT 'Geographic region',
    owner_id            VARCHAR(50)     COMMENT 'CRM user who owns the account',
    created_date        DATE            COMMENT 'Account creation date in CRM',
    last_modified_date  DATE            COMMENT 'Last modification date in CRM'
)
COMMENT = 'Raw SaaS connector data for NordHjem CRM accounts';

-- Contacts — CRM contact records linked to accounts
CREATE OR REPLACE TABLE contacts (
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _sync_id            VARCHAR(50)     COMMENT 'SaaS connector sync batch identifier',
    _is_deleted         BOOLEAN         DEFAULT FALSE COMMENT 'Soft-delete flag from CRM',
    contact_id          VARCHAR(50)     COMMENT 'Natural key — CRM contact identifier',
    account_id          VARCHAR(50)     COMMENT 'FK to accounts',
    first_name          VARCHAR(100)    COMMENT 'Contact first name',
    last_name           VARCHAR(100)    COMMENT 'Contact last name',
    email               VARCHAR(255)    COMMENT 'Contact email address',
    phone               VARCHAR(50)     COMMENT 'Contact phone number',
    title               VARCHAR(100)    COMMENT 'Contact job title',
    department          VARCHAR(100)    COMMENT 'Contact department',
    created_date        DATE            COMMENT 'Contact creation date in CRM',
    last_modified_date  DATE            COMMENT 'Last modification date in CRM'
)
COMMENT = 'Raw SaaS connector data for NordHjem CRM contacts';

-- Cases — service tickets / support cases
CREATE OR REPLACE TABLE cases (
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _sync_id            VARCHAR(50)     COMMENT 'SaaS connector sync batch identifier',
    _is_deleted         BOOLEAN         DEFAULT FALSE COMMENT 'Soft-delete flag from CRM',
    case_id             VARCHAR(50)     COMMENT 'Natural key — CRM case identifier',
    account_id          VARCHAR(50)     COMMENT 'FK to accounts',
    contact_id          VARCHAR(50)     COMMENT 'FK to contacts',
    subject             VARCHAR(500)    COMMENT 'Case subject line',
    description         VARCHAR(4000)   COMMENT 'Case description',
    status              VARCHAR(50)     COMMENT 'Status: open, closed, escalated',
    priority            VARCHAR(50)     COMMENT 'Priority: low, medium, high, critical',
    severity            VARCHAR(20)     COMMENT 'Severity: sev1, sev2, sev3, sev4',
    origin              VARCHAR(50)     COMMENT 'Origin channel: phone, email, web, chat',
    created_date        DATE            COMMENT 'Case creation date',
    closed_date         DATE            COMMENT 'Case closure date (null if open)',
    last_modified_date  DATE            COMMENT 'Last modification date in CRM'
)
COMMENT = 'Raw SaaS connector data for NordHjem CRM service cases';

-- Case Comments — comments on service cases
CREATE OR REPLACE TABLE case_comments (
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _sync_id            VARCHAR(50)     COMMENT 'SaaS connector sync batch identifier',
    _is_deleted         BOOLEAN         DEFAULT FALSE COMMENT 'Soft-delete flag from CRM',
    comment_id          VARCHAR(50)     COMMENT 'Natural key — comment identifier',
    case_id             VARCHAR(50)     COMMENT 'FK to cases',
    body                VARCHAR(4000)   COMMENT 'Comment body text',
    is_public           BOOLEAN         COMMENT 'Whether comment is visible to customer',
    created_by          VARCHAR(50)     COMMENT 'CRM user who created the comment',
    created_date        DATE            COMMENT 'Comment creation date'
)
COMMENT = 'Raw SaaS connector data for NordHjem CRM case comments';

-- Opportunities — sales opportunities
CREATE OR REPLACE TABLE opportunities (
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _sync_id            VARCHAR(50)     COMMENT 'SaaS connector sync batch identifier',
    _is_deleted         BOOLEAN         DEFAULT FALSE COMMENT 'Soft-delete flag from CRM',
    opportunity_id      VARCHAR(50)     COMMENT 'Natural key — opportunity identifier',
    account_id          VARCHAR(50)     COMMENT 'FK to accounts',
    name                VARCHAR(500)    COMMENT 'Opportunity name',
    stage               VARCHAR(50)     COMMENT 'Sales stage: prospecting, negotiation, closed_won, closed_lost',
    amount              NUMBER(12,2)    COMMENT 'Opportunity amount',
    close_date          DATE            COMMENT 'Expected or actual close date',
    probability         INTEGER         COMMENT 'Win probability percentage (0-100)',
    created_date        DATE            COMMENT 'Opportunity creation date',
    last_modified_date  DATE            COMMENT 'Last modification date in CRM'
)
COMMENT = 'Raw SaaS connector data for NordHjem CRM opportunities';

-- Tasks — CRM activity tasks
CREATE OR REPLACE TABLE tasks (
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _sync_id            VARCHAR(50)     COMMENT 'SaaS connector sync batch identifier',
    _is_deleted         BOOLEAN         DEFAULT FALSE COMMENT 'Soft-delete flag from CRM',
    task_id             VARCHAR(50)     COMMENT 'Natural key — task identifier',
    account_id          VARCHAR(50)     COMMENT 'FK to accounts',
    contact_id          VARCHAR(50)     COMMENT 'FK to contacts',
    subject             VARCHAR(500)    COMMENT 'Task subject',
    status              VARCHAR(50)     COMMENT 'Status: open, completed, deferred',
    priority            VARCHAR(50)     COMMENT 'Priority: low, medium, high',
    due_date            DATE            COMMENT 'Task due date',
    completed_date      DATE            COMMENT 'Task completion date (null if open)',
    created_date        DATE            COMMENT 'Task creation date'
)
COMMENT = 'Raw SaaS connector data for NordHjem CRM tasks';

-- Campaigns — marketing campaigns
CREATE OR REPLACE TABLE campaigns (
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _sync_id            VARCHAR(50)     COMMENT 'SaaS connector sync batch identifier',
    _is_deleted         BOOLEAN         DEFAULT FALSE COMMENT 'Soft-delete flag from CRM',
    campaign_id         VARCHAR(50)     COMMENT 'Natural key — campaign identifier',
    name                VARCHAR(500)    COMMENT 'Campaign name',
    type                VARCHAR(50)     COMMENT 'Type: product_launch, webinar, email',
    status              VARCHAR(50)     COMMENT 'Status: planned, active, completed, aborted',
    start_date          DATE            COMMENT 'Campaign start date',
    end_date            DATE            COMMENT 'Campaign end date',
    budget              NUMBER(12,2)    COMMENT 'Campaign budget',
    actual_cost         NUMBER(12,2)    COMMENT 'Actual spend to date',
    created_date        DATE            COMMENT 'Campaign creation date'
)
COMMENT = 'Raw SaaS connector data for NordHjem CRM campaigns';

-- Campaign Members — contacts enrolled in campaigns
CREATE OR REPLACE TABLE campaign_members (
    _loaded_at          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp',
    _sync_id            VARCHAR(50)     COMMENT 'SaaS connector sync batch identifier',
    _is_deleted         BOOLEAN         DEFAULT FALSE COMMENT 'Soft-delete flag from CRM',
    member_id           VARCHAR(50)     COMMENT 'Natural key — campaign member identifier',
    campaign_id         VARCHAR(50)     COMMENT 'FK to campaigns',
    contact_id          VARCHAR(50)     COMMENT 'FK to contacts',
    status              VARCHAR(50)     COMMENT 'Member status: sent, responded, converted',
    first_responded_date DATE           COMMENT 'Date of first response (null if no response)',
    created_date        DATE            COMMENT 'Enrollment date'
)
COMMENT = 'Raw SaaS connector data for NordHjem CRM campaign members';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. INSERT — Load seed data via INSERT INTO ... VALUES
-- ─────────────────────────────────────────────────────────────────────────────
-- Note: CRM CSVs include _loaded_at in the data, so it IS in the INSERT column list.

-- Accounts
INSERT INTO accounts (_loaded_at, _sync_id, _is_deleted, account_id, account_name, industry, website, phone, billing_address, region, owner_id, created_date, last_modified_date)
VALUES
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'ACC-001', 'Lindberg Household', 'residential', NULL, NULL, 'Strandvejen 42 2100 København Ø', 'Hovedstaden', 'USR-101', '2025-01-05', '2025-01-05'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'ACC-002', 'Svensson Household', 'residential', NULL, NULL, 'Vasagatan 15 11120 Stockholm', 'Stockholm', 'USR-102', '2025-01-05', '2025-01-05'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'ACC-003', 'Hansen Consulting AS', 'commercial', 'https://hansen-consulting.example.no', '+4731234567', 'Bygdøy allé 8 0257 Oslo', 'Oslo', 'USR-101', '2025-01-05', '2025-01-05'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'ACC-004', 'Nielsen Household', 'residential', NULL, NULL, 'Algade 22 4000 Roskilde', 'Sjælland', 'USR-103', '2025-01-06', '2025-01-06'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'ACC-005', 'Johansson Energi AB', 'commercial', 'https://johansson-energi.example.se', '+46701234567', 'Kungsgatan 10 41119 Göteborg', 'Västra Götaland', 'USR-102', '2025-01-06', '2025-01-06'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'ACC-006', 'Berg Household', 'residential', NULL, NULL, 'Storgata 5 0155 Oslo', 'Oslo', 'USR-101', '2025-01-07', '2025-01-07'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'ACC-007', 'Petersen Household', 'residential', NULL, NULL, 'Vesterbrogade 100 1620 København V', 'Hovedstaden', 'USR-103', '2025-01-08', '2025-01-08'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'ACC-008', 'Nyström Household', 'residential', NULL, NULL, 'Drottninggatan 55 11121 Stockholm', 'Stockholm', 'USR-102', '2025-01-10', '2025-01-10'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'ACC-009', 'Dahl Eiendom AS', 'commercial', 'https://dahl-eiendom.example.no', '+4741234567', 'Markveien 12 0554 Oslo', 'Oslo', 'USR-101', '2025-01-12', '2025-01-12'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'ACC-010', 'Madsen Household', 'residential', NULL, NULL, 'Nørrebrogade 33 2200 København N', 'Hovedstaden', 'USR-103', '2025-01-15', '2025-01-15'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'ACC-003', 'Hansen Consulting AS', 'commercial', 'https://hansen-consulting.example.no', '+4731234567', 'Karl Johans gate 20 0159 Oslo', 'Oslo', 'USR-101', '2025-01-05', '2025-02-01'),
    ('2025-02-01 02:00:00', 'sync_003', TRUE, 'ACC-007', 'Petersen Household', 'residential', NULL, NULL, 'Vesterbrogade 100 1620 København V', 'Hovedstaden', 'USR-103', '2025-01-08', '2025-02-01'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'ACC-005', 'Johansson Energi AB', 'commercial', 'https://johansson-energi.example.se', '+46701234567', 'Kungsgatan 10 41119 Göteborg', 'Västra Götaland', 'USR-102', '2025-01-06', '2025-02-20');

-- Contacts
INSERT INTO contacts (_loaded_at, _sync_id, _is_deleted, contact_id, account_id, first_name, last_name, email, phone, title, department, created_date, last_modified_date)
VALUES
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'CON-001', 'ACC-001', 'Erik', 'Lindberg', 'erik.lindberg@example.com', '+4520123456', 'Homeowner', NULL, '2025-01-05', '2025-01-05'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'CON-002', 'ACC-002', 'Anna', 'Svensson', 'anna.svensson@example.com', '+4687654321', 'Homeowner', NULL, '2025-01-05', '2025-01-05'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'CON-003', 'ACC-003', 'Lars', 'Hansen', 'lars.hansen@example.com', '+4731234567', 'CEO', 'Management', '2025-01-05', '2025-01-05'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'CON-004', 'ACC-004', 'Mette', 'Nielsen', 'mette.nielsen@example.com', '+4528765432', 'Homeowner', NULL, '2025-01-06', '2025-01-06'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'CON-005', 'ACC-005', 'Olof', 'Johansson', 'olof.johansson@example.com', '+46701234567', 'Facilities Manager', 'Operations', '2025-01-06', '2025-01-06'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'CON-006', 'ACC-006', 'Ingrid', 'Berg', 'ingrid.berg@example.com', '+4790123456', 'Homeowner', NULL, '2025-01-07', '2025-01-07'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'CON-007', 'ACC-007', 'Karl', 'Petersen', 'karl.petersen@example.com', '+4521987654', 'Homeowner', NULL, '2025-01-08', '2025-01-08'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'CON-008', 'ACC-008', 'Sofia', 'Nyström', 'sofia.nystrom@example.com', '+46739876543', 'Homeowner', NULL, '2025-01-10', '2025-01-10'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'CON-009', 'ACC-009', 'Bjørn', 'Dahl', 'bjorn.dahl@example.com', '+4741234567', 'Property Manager', 'Operations', '2025-01-12', '2025-01-12'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'CON-010', 'ACC-010', 'Freya', 'Madsen', 'freya.madsen@example.com', '+4523456789', 'Homeowner', NULL, '2025-01-15', '2025-01-15'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'CON-011', 'ACC-003', 'Kari', 'Olsen', 'kari.olsen@hansen-consulting.example.no', '+4732345678', 'Office Manager', 'Administration', '2025-01-18', '2025-01-18'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CON-002', 'ACC-002', 'Anna', 'Svensson', 'anna.svensson@newmail.se', '+4687654321', 'Homeowner', NULL, '2025-01-05', '2025-01-25'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CON-001', 'ACC-001', 'Erik', 'Lindberg', 'erik.lindberg@example.com', '+4520999888', 'Homeowner', NULL, '2025-01-05', '2025-02-15'),
    ('2025-03-01 02:00:00', 'sync_004', TRUE, 'CON-007', 'ACC-007', 'Karl', 'Petersen', 'karl.petersen@example.com', '+4521987654', 'Homeowner', NULL, '2025-01-08', '2025-03-01');

-- Cases
INSERT INTO cases (_loaded_at, _sync_id, _is_deleted, case_id, account_id, contact_id, subject, description, status, priority, severity, origin, created_date, closed_date, last_modified_date)
VALUES
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'CASE-001', 'ACC-001', 'CON-001', 'Thermostat not connecting to WiFi', 'Smart Thermostat v2 fails to connect after installation. LED shows amber blinking pattern.', 'open', 'high', 'sev2', 'phone', '2025-01-15', NULL, '2025-01-15'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'CASE-002', 'ACC-003', 'CON-003', 'Energy readings seem too high', 'Commercial suite showing 3x expected kWh readings for office space. Possible calibration issue.', 'open', 'medium', 'sev3', 'email', '2025-01-18', NULL, '2025-01-18'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CASE-001', 'ACC-001', 'CON-001', 'Thermostat not connecting to WiFi', 'Smart Thermostat v2 fails to connect after installation. LED shows amber blinking pattern. Resolved by firmware update.', 'closed', 'high', 'sev2', 'phone', '2025-01-15', '2025-01-22', '2025-01-22'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CASE-002', 'ACC-003', 'CON-003', 'Energy readings seem too high', 'Commercial suite showing 3x expected kWh readings for office space. Recalibrated CT clamps.', 'closed', 'medium', 'sev3', 'email', '2025-01-18', '2025-01-28', '2025-01-28'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CASE-003', 'ACC-004', 'CON-004', 'Billing discrepancy on February invoice', 'Monthly amount does not match contract terms. Customer expects 399 but was charged 498.75.', 'open', 'high', 'sev2', 'web', '2025-02-02', NULL, '2025-02-02'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CASE-004', 'ACC-006', 'CON-006', 'Thermostat schedule not saving', 'Programmed heating schedule resets to default after 24 hours.', 'open', 'medium', 'sev3', 'phone', '2025-02-05', NULL, '2025-02-05'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CASE-005', 'ACC-005', 'CON-005', 'Request for additional meter installation', 'Need second energy meter for warehouse section of building.', 'open', 'low', 'sev4', 'email', '2025-02-08', NULL, '2025-02-08'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'CASE-003', 'ACC-004', 'CON-004', 'Billing discrepancy on February invoice', 'Monthly amount does not match contract terms. Corrected in next billing cycle.', 'closed', 'high', 'sev2', 'web', '2025-02-02', '2025-02-15', '2025-02-15'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'CASE-004', 'ACC-006', 'CON-006', 'Thermostat schedule not saving', 'Programmed heating schedule resets to default after 24 hours. Fixed via firmware 2.2.0.', 'closed', 'medium', 'sev3', 'phone', '2025-02-05', '2025-02-20', '2025-02-20'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'CASE-006', 'ACC-002', 'CON-002', 'Energy meter offline intermittently', 'Energy Meter Pro goes offline for 2-3 hours daily. Signal strength appears weak.', 'open', 'high', 'sev2', 'phone', '2025-02-25', NULL, '2025-02-25'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'CASE-007', 'ACC-009', 'CON-009', 'Request for energy audit', 'Would like comprehensive energy audit for all managed properties.', 'open', 'low', 'sev4', 'web', '2025-03-01', NULL, '2025-03-01');

-- Case Comments
INSERT INTO case_comments (_loaded_at, _sync_id, _is_deleted, comment_id, case_id, body, is_public, created_by, created_date)
VALUES
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'CMT-001', 'CASE-001', 'Initial assessment: device firmware may be outdated. Scheduling remote update.', FALSE, 'USR-101', '2025-01-16'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'CMT-002', 'CASE-001', 'Customer confirmed WiFi credentials are correct. Router is 2.4GHz compatible.', TRUE, 'USR-101', '2025-01-17'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'CMT-003', 'CASE-002', 'Dispatching field technician to verify CT clamp installation on main panel.', FALSE, 'USR-102', '2025-01-19'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CMT-004', 'CASE-001', 'Firmware updated to 2.2.0 remotely. Device now connecting successfully.', TRUE, 'USR-101', '2025-01-22'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CMT-005', 'CASE-002', 'CT clamps were installed on wrong phase. Recalibrated and readings now normal.', TRUE, 'USR-102', '2025-01-28'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CMT-006', 'CASE-003', 'Reviewing contract terms and invoice generation logic. Escalating to billing team.', FALSE, 'USR-103', '2025-02-03'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CMT-007', 'CASE-004', 'Known issue with firmware 2.1.0 schedule persistence. Fix available in 2.2.0.', TRUE, 'USR-101', '2025-02-06'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'CMT-008', 'CASE-003', 'Credit note issued for difference. Next invoice will reflect correct amount.', TRUE, 'USR-103', '2025-02-15'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'CMT-009', 'CASE-004', 'Firmware 2.2.0 pushed to device. Customer confirmed schedule now persists.', TRUE, 'USR-101', '2025-02-20'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'CMT-010', 'CASE-006', 'Signal strength test shows -78 dBm. Recommending WiFi extender near meter location.', TRUE, 'USR-102', '2025-02-26'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'CMT-011', 'CASE-005', 'Scheduling site survey for warehouse meter installation. Estimated 2 weeks.', TRUE, 'USR-102', '2025-02-10');

-- Opportunities
INSERT INTO opportunities (_loaded_at, _sync_id, _is_deleted, opportunity_id, account_id, name, stage, amount, close_date, probability, created_date, last_modified_date)
VALUES
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'OPP-001', 'ACC-003', 'Hansen Consulting — Commercial Energy Suite', 'closed_won', 17988.00, '2025-01-05', 100, '2024-12-01', '2025-01-05'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'OPP-002', 'ACC-005', 'Johansson Energi — Commercial Monitoring', 'closed_won', 15588.00, '2025-01-06', 100, '2024-12-05', '2025-01-06'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'OPP-003', 'ACC-009', 'Dahl Eiendom — Multi-property Energy Management', 'negotiation', 35964.00, '2025-03-15', 60, '2025-01-12', '2025-01-12'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'OPP-003', 'ACC-009', 'Dahl Eiendom — Multi-property Energy Management', 'proposal', 35964.00, '2025-03-15', 40, '2025-01-12', '2025-02-01'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'OPP-004', 'ACC-005', 'Johansson Energi — Warehouse Expansion', 'qualification', 7800.00, '2025-04-01', 20, '2025-02-08', '2025-02-08'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'OPP-003', 'ACC-009', 'Dahl Eiendom — Multi-property Energy Management', 'negotiation', 35964.00, '2025-03-30', 70, '2025-01-12', '2025-02-25'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'OPP-004', 'ACC-005', 'Johansson Energi — Warehouse Expansion', 'proposal', 7800.00, '2025-04-15', 50, '2025-02-08', '2025-02-28'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'OPP-005', 'ACC-001', 'Lindberg — Solar Integration Upgrade', 'qualification', 12000.00, '2025-05-01', 15, '2025-03-01', '2025-03-01');

-- Tasks
INSERT INTO tasks (_loaded_at, _sync_id, _is_deleted, task_id, account_id, contact_id, subject, status, priority, due_date, completed_date, created_date)
VALUES
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'TSK-001', 'ACC-001', 'CON-001', 'Follow up on thermostat installation', 'completed', 'high', '2025-01-20', '2025-01-18', '2025-01-10'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'TSK-002', 'ACC-003', 'CON-003', 'Schedule commercial energy audit', 'open', 'medium', '2025-01-25', NULL, '2025-01-12'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'TSK-003', 'ACC-004', 'CON-004', 'Send welcome package and setup guide', 'completed', 'low', '2025-01-15', '2025-01-14', '2025-01-06'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'TSK-002', 'ACC-003', 'CON-003', 'Schedule commercial energy audit', 'completed', 'medium', '2025-01-25', '2025-01-24', '2025-01-12'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'TSK-004', 'ACC-005', 'CON-005', 'Prepare warehouse expansion proposal', 'open', 'high', '2025-02-15', NULL, '2025-02-01'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'TSK-005', 'ACC-009', 'CON-009', 'Multi-property site survey coordination', 'open', 'high', '2025-02-20', NULL, '2025-02-01'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'TSK-006', 'ACC-006', 'CON-006', 'Schedule firmware update for thermostat', 'open', 'medium', '2025-02-10', NULL, '2025-02-05'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'TSK-004', 'ACC-005', 'CON-005', 'Prepare warehouse expansion proposal', 'completed', 'high', '2025-02-15', '2025-02-14', '2025-02-01'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'TSK-005', 'ACC-009', 'CON-009', 'Multi-property site survey coordination', 'completed', 'high', '2025-02-20', '2025-02-19', '2025-02-01'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'TSK-006', 'ACC-006', 'CON-006', 'Schedule firmware update for thermostat', 'completed', 'medium', '2025-02-10', '2025-02-10', '2025-02-05'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'TSK-007', 'ACC-002', 'CON-002', 'Investigate intermittent meter connectivity', 'open', 'high', '2025-03-10', NULL, '2025-02-26');

-- Campaigns
INSERT INTO campaigns (_loaded_at, _sync_id, _is_deleted, campaign_id, name, type, status, start_date, end_date, budget, actual_cost, created_date)
VALUES
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'CMP-001', 'Q1 2025 Smart Home Launch', 'product_launch', 'active', '2025-01-01', '2025-03-31', 50000.00, 12500.00, '2024-12-15'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'CMP-002', 'Nordic Energy Savings Webinar', 'webinar', 'completed', '2025-01-10', '2025-01-10', 5000.00, 4200.00, '2024-12-20'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'CMP-003', 'Commercial Energy Efficiency Program', 'email', 'active', '2025-01-15', '2025-04-15', 15000.00, 3000.00, '2025-01-10'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CMP-001', 'Q1 2025 Smart Home Launch', 'product_launch', 'active', '2025-01-01', '2025-03-31', 50000.00, 28000.00, '2024-12-15'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'CMP-004', 'February Referral Bonus', 'referral', 'active', '2025-02-01', '2025-02-28', 8000.00, 1500.00, '2025-01-28'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'CMP-001', 'Q1 2025 Smart Home Launch', 'product_launch', 'active', '2025-01-01', '2025-03-31', 50000.00, 41000.00, '2024-12-15'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'CMP-004', 'February Referral Bonus', 'referral', 'completed', '2025-02-01', '2025-02-28', 8000.00, 6200.00, '2025-01-28'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'CMP-005', 'Spring Sustainability Campaign', 'content', 'planned', '2025-04-01', '2025-06-30', 20000.00, 0.00, '2025-03-01');

-- Campaign Members
INSERT INTO campaign_members (_loaded_at, _sync_id, _is_deleted, member_id, campaign_id, contact_id, status, first_responded_date, created_date)
VALUES
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'MBR-001', 'CMP-001', 'CON-001', 'sent', NULL, '2025-01-02'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'MBR-002', 'CMP-001', 'CON-002', 'sent', NULL, '2025-01-02'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'MBR-003', 'CMP-001', 'CON-004', 'sent', NULL, '2025-01-06'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'MBR-004', 'CMP-001', 'CON-006', 'sent', NULL, '2025-01-07'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'MBR-005', 'CMP-002', 'CON-001', 'attended', '2025-01-10', '2025-01-05'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'MBR-006', 'CMP-002', 'CON-003', 'attended', '2025-01-10', '2025-01-05'),
    ('2025-01-10 02:00:00', 'sync_001', FALSE, 'MBR-007', 'CMP-002', 'CON-005', 'registered', NULL, '2025-01-05'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'MBR-001', 'CMP-001', 'CON-001', 'responded', '2025-01-12', '2025-01-02'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'MBR-002', 'CMP-001', 'CON-002', 'responded', '2025-01-14', '2025-01-02'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'MBR-008', 'CMP-003', 'CON-003', 'sent', NULL, '2025-01-15'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'MBR-009', 'CMP-003', 'CON-005', 'sent', NULL, '2025-01-15'),
    ('2025-01-20 02:00:00', 'sync_002', FALSE, 'MBR-010', 'CMP-003', 'CON-009', 'sent', NULL, '2025-01-15'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'MBR-008', 'CMP-003', 'CON-003', 'responded', '2025-01-20', '2025-01-15'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'MBR-011', 'CMP-004', 'CON-001', 'responded', '2025-02-05', '2025-02-01'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'MBR-012', 'CMP-004', 'CON-004', 'sent', NULL, '2025-02-01'),
    ('2025-02-01 02:00:00', 'sync_003', FALSE, 'MBR-013', 'CMP-004', 'CON-008', 'sent', NULL, '2025-02-01'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'MBR-012', 'CMP-004', 'CON-004', 'responded', '2025-02-18', '2025-02-01'),
    ('2025-03-01 02:00:00', 'sync_004', FALSE, 'MBR-009', 'CMP-003', 'CON-005', 'responded', '2025-02-10', '2025-01-15');


