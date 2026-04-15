{{
    config(
        materialized='table',
        contract={'enforced': true},
        access='public'
    )
}}

WITH tickets AS (
    SELECT
        ticket_id,
        contact_id
    FROM {{ ref('int_service__ticket_enriched') }}
    WHERE contact_id IS NOT NULL
),

customer_matches AS (
    SELECT DISTINCT
        crm_contact_id,
        customer_id
    FROM {{ ref('int_customer__unified_profile') }}
    WHERE crm_contact_id IS NOT NULL
),

dim_customer AS (
    SELECT
        customer_sk,
        customer_id
    FROM {{ ref('dim_customer') }}
    WHERE is_current = TRUE
),

ticket_customer_pairs AS (
    SELECT DISTINCT
        t.ticket_id,
        dc.customer_sk,
        dc.customer_id
    FROM tickets t
    INNER JOIN customer_matches cm
        ON t.contact_id = cm.crm_contact_id
    INNER JOIN dim_customer dc
        ON cm.customer_id = dc.customer_id
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['ticket_id', 'customer_sk']) }} AS service_ticket_customer_sk,
        ticket_id,
        customer_sk,
        customer_id,
        1.0 / COUNT(*) OVER (PARTITION BY ticket_id) AS allocation_pct
    FROM ticket_customer_pairs
)

SELECT * FROM final
