WITH tickets AS (
    SELECT * FROM {{ ref('int_service__ticket_enriched') }}
),

unified AS (
    SELECT customer_id, crm_contact_id FROM {{ ref('int_customer__unified_profile') }}
    WHERE crm_contact_id IS NOT NULL
),

dim_customer AS (
    SELECT customer_sk, customer_id FROM {{ ref('dim_customer') }} WHERE is_current = TRUE
),

dim_date AS (
    SELECT date_key, full_date FROM {{ ref('dim_date') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['t.ticket_id']) }} AS service_ticket_sk,
        t.ticket_id,
        dc.customer_sk,
        dd_opened.date_key AS opened_date_key,
        dd_closed.date_key AS closed_date_key,
        t.subject,
        t.ticket_status,
        t.priority,
        t.severity,
        t.origin,
        t.opened_at,
        t.assigned_at,
        t.first_response_at,
        t.resolved_at,
        t.closed_at,
        t.time_to_assign_hours,
        t.time_to_first_response_hours,
        t.time_to_resolve_hours,
        t.comment_count
    FROM tickets t
    LEFT JOIN unified u ON t.contact_id = u.crm_contact_id
    LEFT JOIN dim_customer dc ON u.customer_id = dc.customer_id
    LEFT JOIN dim_date dd_opened ON DATE(t.opened_at) = dd_opened.full_date
    LEFT JOIN dim_date dd_closed ON DATE(t.closed_at) = dd_closed.full_date
)

SELECT * FROM final
