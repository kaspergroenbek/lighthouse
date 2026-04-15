-- =============================================================================
-- Dynamic Table: Device Latest Status
-- Near-real-time view of the latest telemetry event per device
-- =============================================================================

SET LIGHTHOUSE_ENV = 'PROD';
SET LIGHTHOUSE_RAW_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_RAW';
SET LIGHTHOUSE_SERVING_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_SERVING';

EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_SERVING_DB;
USE SCHEMA REALTIME;

EXECUTE IMMEDIATE
'CREATE OR REPLACE DYNAMIC TABLE device_latest_status
  TARGET_LAG = ''5 minutes''
  WAREHOUSE = SERVING_WH
AS
WITH ranked_events AS (
    SELECT
        device_id,
        event_type,
        event_timestamp,
        event_data,
        _loaded_at,
        ROW_NUMBER() OVER (
            PARTITION BY device_id
            ORDER BY event_timestamp DESC
        ) AS rn
    FROM ' || $LIGHTHOUSE_RAW_DB || '.IOT.telemetry_events
)

SELECT
    device_id,
    event_type          AS latest_event_type,
    event_timestamp     AS latest_event_timestamp,
    event_data          AS latest_event_data,
    _loaded_at          AS latest_loaded_at,
    CASE
        WHEN DATEDIFF(''minute'', event_timestamp, CURRENT_TIMESTAMP()) <= 15 THEN ''online''
        WHEN DATEDIFF(''minute'', event_timestamp, CURRENT_TIMESTAMP()) <= 60 THEN ''stale''
        ELSE ''offline''
    END AS device_connectivity_status
FROM ranked_events
WHERE rn = 1';
