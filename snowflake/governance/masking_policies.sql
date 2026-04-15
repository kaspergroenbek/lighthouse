-- =============================================================================
-- Governance: Dynamic Data Masking Policies
-- =============================================================================

SET LIGHTHOUSE_ENV = '{{ env }}';
SET LIGHTHOUSE_ANALYTICS_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_ANALYTICS';

EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_ANALYTICS_DB;
USE SCHEMA GOVERNANCE;

CREATE OR REPLACE MASKING POLICY pii_string_mask
    AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ADMIN', 'LIGHTHOUSE_ENGINEER') THEN val
        ELSE '***MASKED***'
    END;

CREATE OR REPLACE MASKING POLICY pii_date_mask
    AS (val DATE) RETURNS DATE ->
    CASE
        WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ADMIN', 'LIGHTHOUSE_ENGINEER') THEN val
        ELSE NULL
    END;

CREATE OR REPLACE MASKING POLICY pii_number_mask
    AS (val NUMBER) RETURNS NUMBER ->
    CASE
        WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ADMIN', 'LIGHTHOUSE_ENGINEER') THEN val
        ELSE NULL
    END;

CREATE OR REPLACE MASKING POLICY pii_timestamp_mask
    AS (val TIMESTAMP_NTZ) RETURNS TIMESTAMP_NTZ ->
    CASE
        WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ADMIN', 'LIGHTHOUSE_ENGINEER') THEN val
        ELSE NULL
    END;

