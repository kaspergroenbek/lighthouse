WITH enriched AS (
    SELECT * FROM {{ ref('int_billing__invoice_enriched') }}
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
        {{ dbt_utils.generate_surrogate_key(['e.line_item_id']) }} AS invoice_line_sk,
        e.line_item_id,
        e.invoice_id,
        dc.customer_sk,
        dh.household_sk,
        dp.product_sk,
        dcon.contract_sk,
        dd.date_key AS invoice_date_key,
        e.line_description,
        e.quantity,
        e.unit_price,
        e.amount,
        e.tax_amount,
        e.net_amount,
        e.invoice_status,
        e.product_category,
        e.revenue_classification
    FROM enriched e
    LEFT JOIN dim_customer dc ON e.customer_id = dc.customer_id
    LEFT JOIN dim_household dh ON e.household_id = dh.household_id
    LEFT JOIN dim_product dp ON e.product_id = dp.product_id
    LEFT JOIN dim_contract dcon ON e.contract_id = dcon.contract_id
    LEFT JOIN dim_date dd ON e.invoice_date = dd.full_date
)

SELECT * FROM final
