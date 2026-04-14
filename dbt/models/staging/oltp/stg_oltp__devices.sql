WITH source AS (
    SELECT * FROM {{ source('oltp', 'devices') }}
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY device_id
            ORDER BY _source_ts DESC
        ) AS _row_num
    FROM source
    WHERE _op != 'DELETE'
),

renamed AS (
    SELECT
        -- Keys
        device_id,

        -- Foreign keys
        household_id,

        -- Attributes
        device_serial,
        device_type,
        manufacturer,
        model,
        firmware_version,
        CAST(installed_at AS DATE) AS installed_at,
        status,
        CAST(created_at AS TIMESTAMP_NTZ) AS created_at,
        CAST(updated_at AS TIMESTAMP_NTZ) AS updated_at,

        -- Metadata
        _source_ts,
        _loaded_at,
        _connector_batch_id

    FROM deduplicated
    WHERE _row_num = 1
)

SELECT * FROM renamed
