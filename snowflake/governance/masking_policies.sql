-- =============================================================================
-- Governance: Dynamic Data Masking Policies
-- =============================================================================

-- PII string masking (full mask for READER, visible for ENGINEER+)
CREATE OR REPLACE MASKING POLICY LIGHTHOUSE_PROD_ANALYTICS.GOVERNANCE.pii_string_mask
    AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ADMIN', 'LIGHTHOUSE_ENGINEER') THEN val
        ELSE '***MASKED***'
    END;

-- PII date masking (null for READER, visible for ENGINEER+)
CREATE OR REPLACE MASKING POLICY LIGHTHOUSE_PROD_ANALYTICS.GOVERNANCE.pii_date_mask
    AS (val DATE) RETURNS DATE ->
    CASE
        WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ADMIN', 'LIGHTHOUSE_ENGINEER') THEN val
        ELSE NULL
    END;

-- PII number masking (null for READER, visible for ENGINEER+)
CREATE OR REPLACE MASKING POLICY LIGHTHOUSE_PROD_ANALYTICS.GOVERNANCE.pii_number_mask
    AS (val NUMBER) RETURNS NUMBER ->
    CASE
        WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ADMIN', 'LIGHTHOUSE_ENGINEER') THEN val
        ELSE NULL
    END;

-- PII timestamp masking (null for READER, visible for ENGINEER+)
CREATE OR REPLACE MASKING POLICY LIGHTHOUSE_PROD_ANALYTICS.GOVERNANCE.pii_timestamp_mask
    AS (val TIMESTAMP_NTZ) RETURNS TIMESTAMP_NTZ ->
    CASE
        WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ADMIN', 'LIGHTHOUSE_ENGINEER') THEN val
        ELSE NULL
    END;
