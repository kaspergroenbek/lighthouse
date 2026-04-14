{{
    config(
        materialized='table'
    )
}}

WITH devices AS (
    SELECT * FROM {{ ref('stg_oltp__devices') }}
),

latest_status AS (
    SELECT
        device_id,
        status AS latest_telemetry_status,
        event_timestamp AS last_status_timestamp,
        ROW_NUMBER() OVER (PARTITION BY device_id ORDER BY event_timestamp DESC) AS rn
    FROM {{ ref('stg_iot__device_status') }}
),

installations AS (
    SELECT * FROM {{ ref('stg_oltp__installations') }}
),

lifecycle AS (
    SELECT
        d.device_id,
        d.device_serial,
        d.household_id,
        d.device_type,
        d.manufacturer,
        d.model,
        d.firmware_version,
        d.installed_at,
        d.status AS source_status,
        ls.latest_telemetry_status,
        ls.last_status_timestamp,
        -- Derive lifecycle state
        CASE
            WHEN d.status = 'decommissioned' THEN 'decommissioned'
            WHEN ls.latest_telemetry_status = 'offline'
                 AND DATEDIFF('hour', ls.last_status_timestamp, CURRENT_TIMESTAMP()) > 72 THEN 'decommissioned'
            WHEN ls.latest_telemetry_status = 'degraded' THEN 'degraded'
            WHEN ls.latest_telemetry_status = 'offline' THEN 'inactive'
            WHEN ls.latest_telemetry_status = 'online' THEN 'active'
            WHEN d.installed_at IS NOT NULL AND d.status = 'active' THEN 'active'
            ELSE 'provisioned'
        END AS lifecycle_state,
        d.created_at,
        d.updated_at
    FROM devices d
    LEFT JOIN latest_status ls
        ON d.device_id = ls.device_id AND ls.rn = 1
)

SELECT * FROM lifecycle
