{#
    Singular test: warns when today's row count for a high-volume model
    deviates more than 30% from the trailing 7-day average.

    Requires the elementary package or a custom on-run-end hook that
    stores row counts in ANALYTICS.TEST_RESULTS.model_row_counts.

    This test queries the row count history table and compares the latest
    count against the 7-day trailing average. Returns a row if the
    deviation exceeds the threshold.
#}

{% set threshold = 0.30 %}

WITH row_count_history AS (
    SELECT
        model_name,
        row_count,
        measured_at::DATE AS measured_date
    FROM {{ target.database }}.TEST_RESULTS.model_row_counts
    WHERE measured_at >= DATEADD('day', -8, CURRENT_DATE())
),

trailing_avg AS (
    SELECT
        model_name,
        AVG(row_count) AS avg_row_count
    FROM row_count_history
    WHERE measured_date < CURRENT_DATE()
      AND measured_date >= DATEADD('day', -7, CURRENT_DATE())
    GROUP BY model_name
    HAVING COUNT(*) >= 3  -- need at least 3 days of history
),

latest_count AS (
    SELECT
        model_name,
        row_count AS latest_row_count
    FROM row_count_history
    WHERE measured_date = CURRENT_DATE()
),

anomalies AS (
    SELECT
        l.model_name,
        l.latest_row_count,
        t.avg_row_count,
        ABS(l.latest_row_count - t.avg_row_count) / NULLIF(t.avg_row_count, 0) AS deviation_pct
    FROM latest_count l
    INNER JOIN trailing_avg t ON l.model_name = t.model_name
    WHERE ABS(l.latest_row_count - t.avg_row_count) / NULLIF(t.avg_row_count, 0) > {{ threshold }}
)

SELECT * FROM anomalies
