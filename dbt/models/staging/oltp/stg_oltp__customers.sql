WITH source AS (
    SELECT * FROM {{ source('oltp', 'customers') }}
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY _source_ts DESC
        ) AS _row_num
    FROM source
    WHERE _op != 'DELETE'
),

renamed AS (
    SELECT
        -- Keys
        customer_id,

        -- Attributes
        LOWER(email) AS email,
        INITCAP(first_name) AS first_name,
        INITCAP(last_name) AS last_name,
        phone,
        address,
        postal_code,
        municipality,
        region,
        country,
        segment,
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
