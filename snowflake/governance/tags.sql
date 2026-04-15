-- =============================================================================
-- Governance: Classification Tags
-- =============================================================================

SET LIGHTHOUSE_ENV = '{{ env }}';
SET LIGHTHOUSE_ANALYTICS_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_ANALYTICS';

EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_ANALYTICS_DB;
CREATE SCHEMA IF NOT EXISTS GOVERNANCE;
USE SCHEMA GOVERNANCE;

CREATE TAG IF NOT EXISTS CLASSIFICATION
    ALLOWED_VALUES 'PII', 'SENSITIVE', 'INTERNAL', 'PUBLIC'
    COMMENT = 'Data classification tag for governance and masking policy assignment';

