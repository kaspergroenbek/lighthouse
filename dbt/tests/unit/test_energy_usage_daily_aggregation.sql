-- Unit test: validate daily aggregation of telemetry readings
-- in int_device__telemetry_daily
-- Verifies:
--   1. total_kwh >= peak_kwh (sum must be >= max)
--   2. total_reading_count > 0 for every row
--   3. No duplicate device_id + reading_date combinations
--   4. avg_temperature is within plausible range when present

WITH daily AS (
    SELECT * FROM {{ ref('int_device__telemetry_daily') }}
),

sum_less_than_peak AS (
    SELECT device_id, reading_date, total_kwh, peak_kwh
    FROM daily
    WHERE total_kwh IS NOT NULL
      AND peak_kwh IS NOT NULL
      AND total_kwh < peak_kwh
),

zero_readings AS (
    SELECT device_id, reading_date, total_reading_count
    FROM daily
    WHERE total_reading_count <= 0
),

duplicate_grain AS (
    SELECT device_id, reading_date, COUNT(*) AS row_count
    FROM daily
    GROUP BY device_id, reading_date
    HAVING COUNT(*) > 1
),

implausible_temperature AS (
    SELECT device_id, reading_date, avg_temperature
    FROM daily
    WHERE avg_temperature IS NOT NULL
      AND (avg_temperature < -50 OR avg_temperature > 80)
)

SELECT 'total_kwh_less_than_peak' AS failure_reason, device_id, reading_date FROM sum_less_than_peak
UNION ALL
SELECT 'zero_reading_count', device_id, reading_date FROM zero_readings
UNION ALL
SELECT 'duplicate_grain', device_id, reading_date FROM duplicate_grain
UNION ALL
SELECT 'implausible_temperature', device_id, reading_date FROM implausible_temperature
