WITH line_items AS (
    SELECT * FROM {{ ref('stg_oltp__invoice_line_items') }}
),

invoices AS (
    SELECT * FROM {{ ref('stg_oltp__invoices') }}
),

products AS (
    SELECT * FROM {{ ref('stg_oltp__products') }}
),

contracts AS (
    SELECT * FROM {{ ref('stg_oltp__contracts') }}
),

enriched AS (
    SELECT
        li.line_item_id,
        li.invoice_id,
        li.product_id,
        li.description AS line_description,
        li.quantity,
        li.unit_price,
        li.amount,
        li.tax_amount,
        inv.customer_id,
        inv.household_id,
        inv.contract_id,
        inv.invoice_date,
        inv.due_date,
        inv.status AS invoice_status,
        p.product_name,
        p.category AS product_category,
        p.pricing_tier,
        c.contract_type,
        c.tariff_plan_id,
        -- Revenue classification
        CASE
            WHEN p.category = 'device' THEN 'hardware_revenue'
            WHEN p.category = 'service' THEN 'service_revenue'
            WHEN p.category = 'bundle' THEN 'bundle_revenue'
            ELSE 'other_revenue'
        END AS revenue_classification,
        -- Net amount
        li.amount - COALESCE(li.tax_amount, 0) AS net_amount
    FROM line_items li
    INNER JOIN invoices inv ON li.invoice_id = inv.invoice_id
    LEFT JOIN products p ON li.product_id = p.product_id
    LEFT JOIN contracts c ON inv.contract_id = c.contract_id
)

SELECT * FROM enriched
