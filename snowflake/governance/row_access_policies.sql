-- =============================================================================
-- Governance: Row Access Policies
-- Region-based access restriction on fct_invoices
-- =============================================================================

SET LIGHTHOUSE_ENV = '{{ env }}';
SET LIGHTHOUSE_ANALYTICS_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_ANALYTICS';

EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_ANALYTICS_DB;
USE SCHEMA GOVERNANCE;

CREATE OR REPLACE ROW ACCESS POLICY region_row_access
    AS (region_val VARCHAR) RETURNS BOOLEAN ->
    CASE
        WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ADMIN', 'LIGHTHOUSE_ENGINEER') THEN TRUE
        WHEN region_val = CURRENT_SESSION_CONTEXT('REGION') THEN TRUE
        ELSE FALSE
    END;

