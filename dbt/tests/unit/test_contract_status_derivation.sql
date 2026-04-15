-- Unit test: validate contract status state machine
-- Valid statuses: active, renewed, cancelled, expired, suspended, service_agreement
-- Business rules:
--   1. All contracts must have a valid status
--   2. Cancelled/expired contracts must have an end_date
--   3. Active contracts must have a start_date
--   4. updated_at must be >= created_at

WITH contracts AS (
    SELECT * FROM {{ ref('stg_oltp__contracts') }}
),

invalid_status AS (
    SELECT contract_id, status
    FROM contracts
    WHERE status NOT IN ('active', 'renewed', 'cancelled', 'expired', 'suspended', 'service_agreement')
),

terminal_without_end_date AS (
    SELECT contract_id, status, end_date
    FROM contracts
    WHERE status IN ('cancelled', 'expired')
      AND end_date IS NULL
),

active_without_start AS (
    SELECT contract_id, status, start_date
    FROM contracts
    WHERE status = 'active'
      AND start_date IS NULL
),

invalid_timestamps AS (
    SELECT contract_id, status, created_at, updated_at
    FROM contracts
    WHERE updated_at < created_at
)

SELECT 'invalid_status' AS failure_reason, contract_id FROM invalid_status
UNION ALL
SELECT 'terminal_missing_end_date', contract_id FROM terminal_without_end_date
UNION ALL
SELECT 'active_missing_start_date', contract_id FROM active_without_start
UNION ALL
SELECT 'updated_before_created', contract_id FROM invalid_timestamps
