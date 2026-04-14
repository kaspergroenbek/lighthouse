-- Unit test: validate deterministic entity matching in int_customer__unified_profile
-- Verifies:
--   1. match_status values are valid
--   2. Matched records have CRM contact_id populated
--   3. oltp_only records do NOT have CRM contact_id
--   4. No duplicate customer_ids (no fan-out from joins)

WITH profile AS (
    SELECT * FROM {{ ref('int_customer__unified_profile') }}
),

invalid_match_status AS (
    SELECT customer_id, match_status
    FROM profile
    WHERE match_status NOT IN ('matched', 'oltp_only', 'crm_only')
),

matched_without_crm AS (
    SELECT customer_id, match_status, crm_contact_id
    FROM profile
    WHERE match_status = 'matched'
      AND crm_contact_id IS NULL
),

oltp_only_with_crm AS (
    SELECT customer_id, match_status, crm_contact_id
    FROM profile
    WHERE match_status = 'oltp_only'
      AND crm_contact_id IS NOT NULL
),

duplicate_customers AS (
    SELECT customer_id, COUNT(*) AS row_count
    FROM profile
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
    HAVING COUNT(*) > 1
)

SELECT 'invalid_match_status' AS failure_reason, customer_id FROM invalid_match_status
UNION ALL
SELECT 'matched_without_crm_contact', customer_id FROM matched_without_crm
UNION ALL
SELECT 'oltp_only_has_crm_contact', customer_id FROM oltp_only_with_crm
UNION ALL
SELECT 'duplicate_customer_id', customer_id FROM duplicate_customers
