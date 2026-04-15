WITH tickets AS (
    SELECT * FROM {{ ref('int_service__ticket_enriched') }}
),

dim_date AS (
    SELECT date_key, full_date FROM {{ ref('dim_date') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['t.ticket_id']) }} AS service_ticket_sk,
        t.ticket_id,
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
    LEFT JOIN dim_date dd_opened ON DATE(t.opened_at) = dd_opened.full_date
    LEFT JOIN dim_date dd_closed ON DATE(t.closed_at) = dd_closed.full_date
)

SELECT * FROM final
