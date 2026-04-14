WITH snapshot AS (
    SELECT * FROM {{ ref('snp_contracts') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['contract_id', 'dbt_valid_from']) }} AS contract_sk,
        contract_id,
        customer_id,
        household_id,
        product_id,
        tariff_plan_id,
        contract_type,
        status,
        start_date,
        end_date,
        monthly_amount,
        created_at,
        updated_at,
        dbt_valid_from AS valid_from,
        dbt_valid_to AS valid_to,
        CASE WHEN dbt_valid_to IS NULL THEN TRUE ELSE FALSE END AS is_current
    FROM snapshot
)

SELECT * FROM final
