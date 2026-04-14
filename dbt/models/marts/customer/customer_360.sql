WITH unified AS (
    SELECT * FROM {{ ref('int_customer__unified_profile') }}
),

contracts AS (
    SELECT
        customer_id,
        COUNT(*) AS total_contracts,
        COUNT(CASE WHEN status = 'active' THEN 1 END) AS active_contracts,
        SUM(monthly_amount) AS total_monthly_amount
    FROM {{ ref('stg_oltp__contracts') }}
    GROUP BY customer_id
),

devices AS (
    SELECT
        h.customer_id,
        COUNT(CASE WHEN d.lifecycle_state = 'active' THEN 1 END) AS active_device_count,
        COUNT(*) AS total_device_count
    FROM {{ ref('int_device__lifecycle') }} d
    INNER JOIN {{ ref('stg_oltp__households') }} h ON d.household_id = h.household_id
    GROUP BY h.customer_id
),

invoices AS (
    SELECT
        customer_id,
        SUM(total_amount) AS lifetime_invoice_total,
        MAX(invoice_date) AS last_invoice_date
    FROM {{ ref('stg_oltp__invoices') }}
    GROUP BY customer_id
),

tickets AS (
    SELECT
        u2.customer_id,
        COUNT(*) AS total_service_tickets,
        MAX(t.opened_at) AS last_ticket_date
    FROM {{ ref('int_service__ticket_enriched') }} t
    LEFT JOIN {{ ref('int_customer__unified_profile') }} u2
        ON t.contact_id = u2.crm_contact_id
    WHERE u2.customer_id IS NOT NULL
    GROUP BY u2.customer_id
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['u.customer_id']) }} AS customer_360_sk,
        u.customer_id,
        u.oltp_email AS email,
        u.first_name,
        u.last_name,
        u.phone,
        u.address,
        u.postal_code,
        u.municipality,
        u.region,
        u.country,
        u.segment,
        u.status,
        u.match_status,
        u.crm_contact_id,
        u.crm_account_name,
        u.crm_title,
        u.crm_department,
        COALESCE(c.total_contracts, 0) AS total_contracts,
        COALESCE(c.active_contracts, 0) AS active_contracts,
        COALESCE(d.active_device_count, 0) AS active_device_count,
        COALESCE(d.total_device_count, 0) AS total_device_count,
        COALESCE(inv.lifetime_invoice_total, 0) AS lifetime_invoice_total,
        COALESCE(tk.total_service_tickets, 0) AS total_service_tickets,
        GREATEST(
            COALESCE(inv.last_invoice_date, '1900-01-01'),
            COALESCE(tk.last_ticket_date, '1900-01-01'::TIMESTAMP_NTZ),
            COALESCE(u.updated_at, '1900-01-01'::TIMESTAMP_NTZ)
        ) AS last_interaction_date,
        u.created_at,
        u.updated_at
    FROM unified u
    LEFT JOIN contracts c ON u.customer_id = c.customer_id
    LEFT JOIN devices d ON u.customer_id = d.customer_id
    LEFT JOIN invoices inv ON u.customer_id = inv.customer_id
    LEFT JOIN tickets tk ON u.customer_id = tk.customer_id
)

SELECT * FROM final
