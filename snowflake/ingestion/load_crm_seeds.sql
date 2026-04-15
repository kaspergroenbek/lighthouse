-- =============================================================================
-- load_crm_seeds.sql — Create raw CRM tables and load SaaS connector seed data
-- =============================================================================
-- Purpose:  Creates raw tables in RAW.CRM for all 8 CRM objects with SaaS
--           connector metadata columns, then loads synthetic seed CSVs via
--           PUT + COPY INTO.
--
-- Prerequisites:
--   - 01_databases.sql  (LIGHTHOUSE_{ENV}_RAW database)
--   - 05_schemas.sql    (RAW.CRM schema)
--   - 06_stages.sql     (@RAW.CRM.crm_stage)
--   - 08_file_formats.sql (RAW.CRM.csv_format)
--
-- SaaS connector metadata columns:
--   _loaded_at   — Platform ingestion timestamp (auto-populated)
--   _sync_id     — Connector sync batch identifier
--   _is_deleted  — Soft-delete flag from SaaS source
--
-- Idempotency: Uses CREATE OR REPLACE TABLE — safe to re-run.
-- =============================================================================

USE WAREHOUSE INGESTION_WH;
USE DATABASE LIGHTHOUSE_DEV_RAW;
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
-- 2. PUT — Upload seed CSV files to internal stage
-- ─────────────────────────────────────────────────────────────────────────────

PUT file://data/crm/accounts.csv         @crm_stage/accounts/         AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/crm/contacts.csv         @crm_stage/contacts/         AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/crm/cases.csv            @crm_stage/cases/            AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/crm/case_comments.csv    @crm_stage/case_comments/    AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/crm/opportunities.csv    @crm_stage/opportunities/    AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/crm/tasks.csv            @crm_stage/tasks/            AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/crm/campaigns.csv        @crm_stage/campaigns/        AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/crm/campaign_members.csv @crm_stage/campaign_members/ AUTO_COMPRESS = TRUE OVERWRITE = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. COPY INTO — Load seed data from stage into raw tables
-- ─────────────────────────────────────────────────────────────────────────────

COPY INTO accounts
    FROM @crm_stage/accounts/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO contacts
    FROM @crm_stage/contacts/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO cases
    FROM @crm_stage/cases/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO case_comments
    FROM @crm_stage/case_comments/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO opportunities
    FROM @crm_stage/opportunities/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO tasks
    FROM @crm_stage/tasks/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO campaigns
    FROM @crm_stage/campaigns/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';

COPY INTO campaign_members
    FROM @crm_stage/campaign_members/
    FILE_FORMAT = (FORMAT_NAME = csv_format)
    ON_ERROR = 'ABORT_STATEMENT';
