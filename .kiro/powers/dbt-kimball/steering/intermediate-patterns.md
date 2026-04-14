# dbt Intermediate Layer Patterns

## Naming: `int_{domain}__{description}`

## Entity Matching Pattern

```sql
WITH oltp_customers AS (
    SELECT * FROM {{ ref('stg_oltp__customers') }}
),
crm_contacts AS (
    SELECT * FROM {{ ref('stg_crm__contacts') }}
),
matched AS (
    SELECT
        COALESCE(o.customer_id, c.customer_id) AS customer_id,
        CASE
            WHEN o.customer_id IS NOT NULL AND c.customer_id IS NOT NULL THEN 'matched'
            WHEN o.customer_id IS NOT NULL THEN 'oltp_only'
            ELSE 'crm_only'
        END AS match_status,
        COALESCE(o.first_name, c.first_name) AS first_name
    FROM oltp_customers o
    FULL OUTER JOIN crm_contacts c
        ON o.customer_id = c.customer_id
        OR LOWER(o.email) = LOWER(c.email)
)
SELECT * FROM matched
```

## Rules

- MUST set model access to `protected`
- MUST NOT be exposed as data product interfaces
- MUST handle entity matching with explicit non-match handling
- Business logic transformations belong HERE, not in staging or marts
- Use `ephemeral`/`view` for lightweight, `table`/`incremental` for heavy joins
