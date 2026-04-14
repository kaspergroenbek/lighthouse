WITH source AS (
    SELECT * FROM {{ source('iot', 'telemetry_events') }}
    WHERE event_type = 'energy_reading'
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
        event_data:payload.kwh_reading::NUMBER(12,4) AS kwh_reading,
        event_data:payload.voltage::NUMBER(8,2) AS voltage,
        event_data:payload.current::NUMBER(8,2) AS current_amps,

        -- Metadata
        _loaded_at,
        _ingestion_date

    FROM deduplicated
    WHERE _row_num = 1
)

SELECT * FROM extracted
