WITH source AS (
    SELECT * FROM {{ source('oltp', 'households') }}
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY household_id
            ORDER BY _source_ts DESC
        ) AS _row_num
    FROM source
    WHERE _op != 'DELETE'
),

renamed AS (
    SELECT
        -- Keys
        household_id,

        -- Foreign keys
        customer_id,

        -- Attributes
        address,
        postal_code,
        municipality,
        country,
        household_type,
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
