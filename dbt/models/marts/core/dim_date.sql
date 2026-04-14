WITH source AS (
    SELECT * FROM {{ ref('dim_date_seed') }}
),

final AS (
    SELECT
        date_key,
        CAST(full_date AS DATE) AS full_date,
        day_of_week,
        day_of_week_num,
        week_number_iso,
        month,
        month_name,
        quarter,
        year,
        is_weekend,
        is_danish_public_holiday,
        fiscal_year,
        fiscal_quarter
    FROM source
)

SELECT * FROM final
