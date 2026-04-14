-- =============================================================================
-- Dynamic Table: Device Latest Status
-- Near-real-time view of the latest telemetry event per device
-- =============================================================================

CREATE OR REPLACE DYNAMIC TABLE LIGHTHOUSE_PROD_SERVING.REALTIME.device_latest_status
  TARGET_LAG = '5 minutes'
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
    FROM LIGHTHOUSE_PROD_RAW.IOT.telemetry_events
)

SELECT
    device_id,
    event_type          AS latest_event_type,
    event_timestamp     AS latest_event_timestamp,
    event_data          AS latest_event_data,
    _loaded_at          AS latest_loaded_at,
    CASE
        WHEN DATEDIFF('minute', event_timestamp, CURRENT_TIMESTAMP()) <= 15 THEN 'online'
        WHEN DATEDIFF('minute', event_timestamp, CURRENT_TIMESTAMP()) <= 60 THEN 'stale'
        ELSE 'offline'
    END AS device_connectivity_status
FROM ranked_events
WHERE rn = 1;
