WITH contracts AS (
    SELECT * FROM {{ ref('stg_oltp__contracts') }}
),

dim_customer AS (
    SELECT customer_sk, customer_id FROM {{ ref('dim_customer') }} WHERE is_current = TRUE
),

dim_household AS (
    SELECT household_sk, household_id FROM {{ ref('dim_household') }}
),

dim_product AS (
    SELECT product_sk, product_id FROM {{ ref('dim_product') }}
),

dim_contract AS (
    SELECT contract_sk, contract_id FROM {{ ref('dim_contract') }} WHERE is_current = TRUE
),

dim_date AS (
    SELECT date_key, full_date FROM {{ ref('dim_date') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['c.contract_id']) }} AS contract_lifecycle_sk,
        c.contract_id,
        dc.customer_sk,
        dh.household_sk,
        dp.product_sk,
        dcon.contract_sk,
        dd_start.date_key AS start_date_key,
        dd_end.date_key AS end_date_key,
        c.contract_type,
        c.status,
        c.created_at,
        c.created_at AS created_at_milestone,
        CASE WHEN c.status IN ('active', 'renewed', 'cancelled', 'expired') THEN c.start_date END AS activated_at,
        CASE WHEN c.status = 'renewed' THEN c.updated_at END AS renewed_at,
        CASE WHEN c.status = 'cancelled' THEN c.updated_at END AS cancelled_at,
        DATEDIFF('day', c.start_date, COALESCE(c.end_date, CURRENT_DATE())) AS contract_duration_days,
        c.monthly_amount
    FROM contracts c
    LEFT JOIN dim_customer dc ON c.customer_id = dc.customer_id
    LEFT JOIN dim_household dh ON c.household_id = dh.household_id
    LEFT JOIN dim_product dp ON c.product_id = dp.product_id
    LEFT JOIN dim_contract dcon ON c.contract_id = dcon.contract_id
    LEFT JOIN dim_date dd_start ON c.start_date = dd_start.full_date
    LEFT JOIN dim_date dd_end ON c.end_date = dd_end.full_date
)

SELECT * FROM final
