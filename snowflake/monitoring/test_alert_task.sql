-- =============================================================================
-- Monitoring: Test Alert Task
-- Reads test results and triggers alerts on error-severity failures
-- =============================================================================

CREATE OR REPLACE TASK LIGHTHOUSE_PROD_ANALYTICS.TEST_RESULTS.test_failure_alert_task
    WAREHOUSE = TRANSFORM_WH
    SCHEDULE = 'USING CRON 0 */2 * * * UTC'  -- Every 2 hours
AS
BEGIN
    LET failure_count INTEGER;

    SELECT COUNT(*) INTO :failure_count
    FROM LIGHTHOUSE_PROD_ANALYTICS.TEST_RESULTS.elementary_test_results
    WHERE test_timestamp >= DATEADD('hour', -2, CURRENT_TIMESTAMP())
      AND status = 'fail'
      AND severity = 'ERROR';

    IF (:failure_count > 0) THEN
        INSERT INTO LIGHTHOUSE_PROD_ANALYTICS.TEST_RESULTS.test_alerts (
            alert_timestamp, failure_count, alert_message, alert_status
        )
        SELECT
            CURRENT_TIMESTAMP(),
            :failure_count,
            'ERROR-severity dbt test failures detected: ' || :failure_count || ' failures in last 2 hours',
            'NEW';
    END IF;
END;

-- Create alerts table if not exists
CREATE TABLE IF NOT EXISTS LIGHTHOUSE_PROD_ANALYTICS.TEST_RESULTS.test_alerts (
    alert_id        INTEGER AUTOINCREMENT,
    alert_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    failure_count   INTEGER,
    alert_message   VARCHAR,
    alert_status    VARCHAR DEFAULT 'NEW'
);

-- Enable the task
ALTER TASK IF EXISTS LIGHTHOUSE_PROD_ANALYTICS.TEST_RESULTS.test_failure_alert_task RESUME;
