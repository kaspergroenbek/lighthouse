WITH cases AS (
    SELECT * FROM {{ ref('stg_crm__cases') }}
),

case_comments AS (
    SELECT
        case_id,
        MIN(created_date) AS first_comment_date,
        COUNT(*) AS comment_count
    FROM {{ ref('stg_crm__case_comments') }}
    GROUP BY case_id
),

contacts AS (
    SELECT * FROM {{ ref('stg_crm__contacts') }}
),

enriched AS (
    SELECT
        c.case_id AS ticket_id,
        c.account_id,
        c.contact_id,
        ct.email AS contact_email,
        c.subject,
        c.description,
        c.status AS ticket_status,
        c.priority,
        c.severity,
        c.origin,
        -- Milestone timestamps
        c.created_date AS opened_at,
        -- Simulate assigned_at as created_date + 1 day for demo (in production this comes from CRM workflow)
        DATEADD('day', 1, c.created_date) AS assigned_at,
        cc.first_comment_date AS first_response_at,
        CASE WHEN c.status = 'closed' THEN c.closed_date ELSE NULL END AS resolved_at,
        c.closed_date AS closed_at,
        -- Duration measures (hours)
        DATEDIFF('hour', c.created_date, DATEADD('day', 1, c.created_date)) AS time_to_assign_hours,
        DATEDIFF('hour', c.created_date, cc.first_comment_date) AS time_to_first_response_hours,
        DATEDIFF('hour', c.created_date, c.closed_date) AS time_to_resolve_hours,
        cc.comment_count,
        c.last_modified_date
    FROM cases c
    LEFT JOIN case_comments cc ON c.case_id = cc.case_id
    LEFT JOIN contacts ct ON c.contact_id = ct.contact_id
)

SELECT * FROM enriched
