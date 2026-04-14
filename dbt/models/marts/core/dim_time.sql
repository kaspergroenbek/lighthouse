WITH source AS (
    SELECT * FROM {{ ref('dim_time_seed') }}
),

final AS (
    SELECT
        time_key,
        hour,
        minute,
        time_of_day_band,
        is_business_hour
    FROM source
)

SELECT * FROM final
