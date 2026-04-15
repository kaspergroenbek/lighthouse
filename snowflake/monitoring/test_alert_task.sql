-- =============================================================================
-- Monitoring: Test Alert Task
-- Reads test results and triggers alerts on error-severity failures
-- =============================================================================

SET LIGHTHOUSE_ENV = 'PROD';
SET LIGHTHOUSE_ANALYTICS_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_ANALYTICS';

EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_ANALYTICS_DB;
USE SCHEMA TEST_RESULTS;

CREATE TABLE IF NOT EXISTS test_alerts (
    alert_id        INTEGER AUTOINCREMENT,
    alert_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    failure_count   INTEGER,
    alert_message   VARCHAR,
    alert_status    VARCHAR DEFAULT 'NEW'
);

CREATE OR REPLACE TASK test_failure_alert_task
    WAREHOUSE = TRANSFORM_WH
    SCHEDULE = 'USING CRON 0 */2 * * * UTC'
AS
BEGIN
    LET failure_count INTEGER;

    SELECT COUNT(*) INTO :failure_count
    FROM elementary_test_results
    WHERE test_timestamp >= DATEADD('hour', -2, CURRENT_TIMESTAMP())
      AND status = 'fail'
      AND severity = 'ERROR';

    IF (:failure_count > 0) THEN
        INSERT INTO test_alerts (
            alert_timestamp, failure_count, alert_message, alert_status
        )
        SELECT
            CURRENT_TIMESTAMP(),
            :failure_count,
            'ERROR-severity dbt test failures detected: ' || :failure_count || ' failures in last 2 hours',
            'NEW';
    END IF;
END;

ALTER TASK IF EXISTS test_failure_alert_task RESUME;
