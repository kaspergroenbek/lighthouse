-- =============================================================================
-- Governance: Classification Tags
-- =============================================================================

-- Create governance schema if not exists
CREATE SCHEMA IF NOT EXISTS LIGHTHOUSE_PROD_ANALYTICS.GOVERNANCE;

-- Classification tag with allowed values
CREATE TAG IF NOT EXISTS LIGHTHOUSE_PROD_ANALYTICS.GOVERNANCE.CLASSIFICATION
    ALLOWED_VALUES 'PII', 'SENSITIVE', 'INTERNAL', 'PUBLIC'
    COMMENT = 'Data classification tag for governance and masking policy assignment';
