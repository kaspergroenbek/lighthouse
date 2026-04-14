WITH source AS (
    SELECT * FROM {{ source('oltp', 'payments') }}
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY payment_id
            ORDER BY _source_ts DESC
        ) AS _row_num
    FROM source
    WHERE _op != 'DELETE'
),

renamed AS (
    SELECT
        -- Keys
        payment_id,

        -- Foreign keys
        invoice_id,
        customer_id,

        -- Attributes
        CAST(payment_date AS DATE) AS payment_date,
        CAST(payment_amount AS NUMBER(12, 2)) AS payment_amount,
        payment_method,
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
