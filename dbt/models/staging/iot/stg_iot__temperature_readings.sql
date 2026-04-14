WITH source AS (
    SELECT * FROM {{ source('iot', 'telemetry_events') }}
    WHERE event_type = 'temperature_reading'
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
        event_data:payload.temperature_celsius::NUMBER(6,2) AS temperature_celsius,
        event_data:payload.humidity_percent::INTEGER AS humidity_percent,
        event_data:payload.target_temperature::NUMBER(6,2) AS target_temperature,

        -- Metadata
        _loaded_at,
        _ingestion_date

    FROM deduplicated
    WHERE _row_num = 1
)

SELECT * FROM extracted
