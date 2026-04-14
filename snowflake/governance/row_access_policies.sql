-- =============================================================================
-- Governance: Row Access Policies
-- Region-based access restriction on fct_invoices
-- =============================================================================

-- Row access policy: restrict invoice data by region based on role mapping
-- LIGHTHOUSE_ADMIN and LIGHTHOUSE_ENGINEER see all rows
-- Other roles see only rows matching their assigned region (via session variable)
CREATE OR REPLACE ROW ACCESS POLICY LIGHTHOUSE_PROD_ANALYTICS.GOVERNANCE.region_row_access
    AS (region_val VARCHAR) RETURNS BOOLEAN ->
    CASE
        WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ADMIN', 'LIGHTHOUSE_ENGINEER') THEN TRUE
        WHEN region_val = CURRENT_SESSION_CONTEXT('REGION') THEN TRUE
        ELSE FALSE
    END;
