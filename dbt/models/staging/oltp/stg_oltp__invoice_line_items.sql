WITH source AS (
    SELECT * FROM {{ source('oltp', 'invoice_line_items') }}
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY line_item_id
            ORDER BY _source_ts DESC
        ) AS _row_num
    FROM source
    WHERE _op != 'DELETE'
),

renamed AS (
    SELECT
        -- Keys
        line_item_id,

        -- Foreign keys
        invoice_id,
        product_id,

        -- Attributes
        description,
        quantity,
        CAST(unit_price AS NUMBER(12, 2)) AS unit_price,
        CAST(amount AS NUMBER(12, 2)) AS amount,
        CAST(tax_amount AS NUMBER(12, 2)) AS tax_amount,
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
