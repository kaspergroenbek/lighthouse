WITH payments AS (
    SELECT * FROM {{ ref('stg_oltp__payments') }}
),

invoices AS (
    SELECT invoice_id, customer_id, household_id, contract_id, due_date
    FROM {{ ref('stg_oltp__invoices') }}
),

dim_customer AS (
    SELECT customer_sk, customer_id FROM {{ ref('dim_customer') }} WHERE is_current = TRUE
),

dim_household AS (
    SELECT household_sk, household_id FROM {{ ref('dim_household') }}
),

dim_contract AS (
    SELECT contract_sk, contract_id FROM {{ ref('dim_contract') }} WHERE is_current = TRUE
),

dim_date AS (
    SELECT date_key, full_date FROM {{ ref('dim_date') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['p.payment_id']) }} AS payment_sk,
        p.payment_id,
        p.invoice_id,
        dc.customer_sk,
        dh.household_sk,
        dcon.contract_sk,
        dd.date_key AS payment_date_key,
        p.payment_amount,
        p.payment_method,
        p.status AS payment_status,
        CASE WHEN p.payment_date > inv.due_date THEN TRUE ELSE FALSE END AS is_late_payment
    FROM payments p
    LEFT JOIN invoices inv ON p.invoice_id = inv.invoice_id
    LEFT JOIN dim_customer dc ON p.customer_id = dc.customer_id
    LEFT JOIN dim_household dh ON inv.household_id = dh.household_id
    LEFT JOIN dim_contract dcon ON inv.contract_id = dcon.contract_id
    LEFT JOIN dim_date dd ON p.payment_date = dd.full_date
)

SELECT * FROM final
