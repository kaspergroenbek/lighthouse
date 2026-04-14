WITH source AS (
    SELECT * FROM {{ ref('stg_oltp__products') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['product_id']) }} AS product_sk,
        product_id,
        product_name,
        category,
        description,
        pricing_tier,
        is_active,
        created_at,
        updated_at
    FROM source
)

SELECT * FROM final
