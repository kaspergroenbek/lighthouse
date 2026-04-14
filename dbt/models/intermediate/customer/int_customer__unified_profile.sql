{{
    config(
        materialized='table'
    )
}}

WITH oltp_customers AS (
    SELECT * FROM {{ ref('stg_oltp__customers') }}
),

crm_contacts AS (
    SELECT * FROM {{ ref('stg_crm__contacts') }}
),

crm_accounts AS (
    SELECT * FROM {{ ref('stg_crm__accounts') }}
),

-- Match OLTP customers to CRM contacts on email (primary) or customer_id mapping
matched AS (
    SELECT
        o.customer_id,
        o.email AS oltp_email,
        o.first_name,
        o.last_name,
        o.phone,
        o.address,
        o.postal_code,
        o.municipality,
        o.region,
        o.country,
        o.segment,
        o.status,
        o.created_at,
        o.updated_at,
        c.contact_id AS crm_contact_id,
        c.account_id AS crm_account_id,
        c.title AS crm_title,
        c.department AS crm_department,
        a.account_name AS crm_account_name,
        CASE
            WHEN o.customer_id IS NOT NULL AND c.contact_id IS NOT NULL THEN 'matched'
            WHEN o.customer_id IS NOT NULL THEN 'oltp_only'
            ELSE 'crm_only'
        END AS match_status
    FROM oltp_customers o
    LEFT JOIN crm_contacts c
        ON LOWER(o.email) = LOWER(c.email)
    LEFT JOIN crm_accounts a
        ON c.account_id = a.account_id
)

SELECT * FROM matched
