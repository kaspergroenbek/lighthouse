WITH source AS (
    SELECT * FROM {{ ref('stg_oltp__households') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['household_id']) }} AS household_sk,
        household_id,
        customer_id,
        address,
        postal_code,
        municipality,
        country,
        household_type,
        created_at,
        updated_at
    FROM source
)

SELECT * FROM final
