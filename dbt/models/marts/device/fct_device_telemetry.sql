{{
    config(
        cluster_by=['date_key']
    )
}}

WITH energy AS (
    SELECT device_id, event_timestamp, 'energy_reading' AS event_type, kwh_reading AS reading_value
    FROM {{ ref('stg_iot__energy_readings') }}
),

temperature AS (
    SELECT device_id, event_timestamp, 'temperature_reading' AS event_type, temperature_celsius AS reading_value
    FROM {{ ref('stg_iot__temperature_readings') }}
),

status_events AS (
    SELECT device_id, event_timestamp, 'device_status' AS event_type, NULL AS reading_value
    FROM {{ ref('stg_iot__device_status') }}
),

alerts AS (
    SELECT device_id, event_timestamp, 'alert_event' AS event_type, actual_value AS reading_value
    FROM {{ ref('stg_iot__alert_events') }}
),

all_events AS (
    SELECT * FROM energy
    UNION ALL SELECT * FROM temperature
    UNION ALL SELECT * FROM status_events
    UNION ALL SELECT * FROM alerts
),

devices AS (
    SELECT device_sk, device_id, household_id FROM {{ ref('dim_device') }}
),

dim_household AS (
    SELECT household_sk, household_id FROM {{ ref('dim_household') }}
),

dim_date AS (
    SELECT date_key, full_date FROM {{ ref('dim_date') }}
),

dim_time AS (
    SELECT time_key, hour, minute FROM {{ ref('dim_time') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['ae.device_id', 'ae.event_timestamp', 'ae.event_type']) }} AS telemetry_sk,
        d.device_sk,
        dh.household_sk,
        dd.date_key,
        dt.time_key,
        ae.device_id,
        ae.event_timestamp,
        ae.event_type,
        ae.reading_value
    FROM all_events ae
    LEFT JOIN devices d ON ae.device_id = d.device_id
    LEFT JOIN dim_household dh ON d.household_id = dh.household_id
    LEFT JOIN dim_date dd ON DATE(ae.event_timestamp) = dd.full_date
    LEFT JOIN dim_time dt ON HOUR(ae.event_timestamp) * 60 + MINUTE(ae.event_timestamp) = dt.time_key
)

SELECT * FROM final
