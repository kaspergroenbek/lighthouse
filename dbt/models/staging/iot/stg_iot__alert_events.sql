WITH source AS (
    SELECT * FROM {{ source('iot', 'telemetry_events') }}
    WHERE event_type = 'alert_event'
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
        event_data:payload.alert_type::VARCHAR AS alert_type,
        event_data:payload.severity::VARCHAR AS severity,
        event_data:payload.message::VARCHAR AS message,
        event_data:payload.threshold_value::NUMBER(12,4) AS threshold_value,
        event_data:payload.actual_value::NUMBER(12,4) AS actual_value,

        -- Metadata
        _loaded_at,
        _ingestion_date

    FROM deduplicated
    WHERE _row_num = 1
)

SELECT * FROM extracted
