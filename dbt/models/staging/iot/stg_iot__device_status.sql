WITH source AS (
    SELECT * FROM {{ source('iot', 'telemetry_events') }}
    WHERE event_type = 'device_status'
    {% if is_incremental() %}
        AND _loaded_at > (SELECT MAX(_loaded_at) FROM {{ this }})
    {% endif %}
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY device_id, event_timestamp
            ORDER BY _loaded_at DESC
        ) AS _row_num
    FROM source
),

extracted AS (
    SELECT
        -- Keys
        device_id,
        event_timestamp,

        -- Extracted payload fields
        event_data:payload.status::VARCHAR AS status,
        event_data:payload.battery_level::INTEGER AS battery_level,
        event_data:payload.signal_strength::INTEGER AS signal_strength,

        -- Metadata
        _loaded_at,
        _ingestion_date

    FROM deduplicated
    WHERE _row_num = 1
)

SELECT * FROM extracted
