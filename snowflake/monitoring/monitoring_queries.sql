-- =============================================================================
-- Monitoring Queries: Cost, Performance, and Freshness
-- Run against SNOWFLAKE.ACCOUNT_USAGE views
-- =============================================================================

-- 1. Daily credit consumption by warehouse (last 30 days)
SELECT
    warehouse_name,
    DATE_TRUNC('day', start_time) AS usage_date,
    SUM(credits_used) AS total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY warehouse_name, usage_date
ORDER BY usage_date DESC, total_credits DESC;

-- 2. Longest-running queries (last 7 days, top 20)
SELECT
    query_id,
    user_name,
    warehouse_name,
    execution_status,
    total_elapsed_time / 1000 AS elapsed_seconds,
    query_text
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_DATE())
  AND execution_status = 'SUCCESS'
ORDER BY total_elapsed_time DESC
LIMIT 20;

-- 3. Failed task executions (last 7 days)
SELECT
    name AS task_name,
    database_name,
    schema_name,
    state,
    error_code,
    error_message,
    scheduled_time,
    completed_time
FROM SNOWFLAKE.ACCOUNT_USAGE.TASK_HISTORY
WHERE scheduled_time >= DATEADD('day', -7, CURRENT_DATE())
  AND state = 'FAILED'
ORDER BY scheduled_time DESC;

-- 4. Data product freshness check
SELECT
    table_catalog AS database_name,
    table_schema,
    table_name,
    last_altered AS last_modified,
    DATEDIFF('minute', last_altered, CURRENT_TIMESTAMP()) AS minutes_since_update,
    CASE
        WHEN DATEDIFF('minute', last_altered, CURRENT_TIMESTAMP()) <= 60 THEN 'FRESH'
        WHEN DATEDIFF('minute', last_altered, CURRENT_TIMESTAMP()) <= 120 THEN 'STALE'
        ELSE 'CRITICAL'
    END AS freshness_status
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES
WHERE table_catalog LIKE 'LIGHTHOUSE_%'
  AND table_schema = 'MARTS'
  AND deleted IS NULL
ORDER BY minutes_since_update DESC;
