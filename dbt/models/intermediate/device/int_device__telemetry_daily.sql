{{
    config(
        materialized='table'
    )
}}

WITH energy_readings AS (
    SELECT * FROM {{ ref('stg_iot__energy_readings') }}
),

temperature_readings AS (
    SELECT * FROM {{ ref('stg_iot__temperature_readings') }}
),

-- Daily energy aggregation per device
daily_energy AS (
    SELECT
        device_id,
        DATE(event_timestamp) AS reading_date,
        SUM(kwh_reading) AS total_kwh,
        MAX(kwh_reading) AS peak_kwh,
        COUNT(*) AS energy_reading_count
    FROM energy_readings
    GROUP BY device_id, DATE(event_timestamp)
),

-- Daily temperature aggregation per device
daily_temperature AS (
    SELECT
        device_id,
        DATE(event_timestamp) AS reading_date,
        AVG(temperature_celsius) AS avg_temperature,
        COUNT(*) AS temperature_reading_count
    FROM temperature_readings
    GROUP BY device_id, DATE(event_timestamp)
),

combined AS (
    SELECT
        COALESCE(e.device_id, t.device_id) AS device_id,
        COALESCE(e.reading_date, t.reading_date) AS reading_date,
        e.total_kwh,
        e.peak_kwh,
        t.avg_temperature,
        COALESCE(e.energy_reading_count, 0) + COALESCE(t.temperature_reading_count, 0) AS total_reading_count
    FROM daily_energy e
    FULL OUTER JOIN daily_temperature t
        ON e.device_id = t.device_id AND e.reading_date = t.reading_date
)

SELECT * FROM combined
