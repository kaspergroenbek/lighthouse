{{
    config(
        materialized='table',
        contract={'enforced': true},
        access='public'
    )
}}

WITH snapshot AS (
    SELECT * FROM {{ ref('snp_customers') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'dbt_valid_from']) }} AS customer_sk,
    customer_id,
    email,
    first_name,
    last_name,
    phone,
    address,
    postal_code,
    municipality,
    region,
    country,
    segment,
    status,
    dbt_valid_from AS valid_from,
    dbt_valid_to AS valid_to,
    CASE WHEN dbt_valid_to IS NULL THEN TRUE ELSE FALSE END AS is_current
FROM snapshot
