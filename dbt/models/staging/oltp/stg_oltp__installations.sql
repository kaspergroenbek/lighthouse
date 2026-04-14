WITH source AS (
    SELECT * FROM {{ source('oltp', 'installations') }}
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY installation_id
            ORDER BY _source_ts DESC
        ) AS _row_num
    FROM source
    WHERE _op != 'DELETE'
),

renamed AS (
    SELECT
        -- Keys
        installation_id,

        -- Foreign keys
        household_id,

        -- Attributes
        CAST(installation_date AS DATE) AS installation_date,
        installer_partner_id,
        status,
        notes,
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
