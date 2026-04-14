{{
    config(
        cluster_by=['date_key']
    )
}}

WITH daily AS (
    SELECT * FROM {{ ref('int_device__telemetry_daily') }}
),

devices AS (
    SELECT device_sk, device_id, household_id FROM {{ ref('dim_device') }}
),

dim_household AS (
    SELECT household_sk, household_id, customer_id FROM {{ ref('dim_household') }}
),

dim_customer AS (
    SELECT customer_sk, customer_id FROM {{ ref('dim_customer') }} WHERE is_current = TRUE
),

dim_date AS (
    SELECT date_key, full_date FROM {{ ref('dim_date') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['d.device_id', 'daily.reading_date']) }} AS energy_usage_daily_sk,
        d.device_sk,
        dh.household_sk,
        dc.customer_sk,
        dd.date_key,
        daily.device_id,
        daily.reading_date,
        daily.total_kwh,
        daily.peak_kwh,
        daily.avg_temperature,
        daily.total_reading_count AS reading_count
    FROM daily
    LEFT JOIN devices d ON daily.device_id = d.device_id
    LEFT JOIN dim_household dh ON d.household_id = dh.household_id
    LEFT JOIN dim_customer dc ON dh.customer_id = dc.customer_id
    LEFT JOIN dim_date dd ON daily.reading_date = dd.full_date
)

SELECT * FROM final
