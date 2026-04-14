WITH source AS (
    SELECT * FROM {{ source('oltp', 'invoices') }}
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY invoice_id
            ORDER BY _source_ts DESC
        ) AS _row_num
    FROM source
    WHERE _op != 'DELETE'
),

renamed AS (
    SELECT
        -- Keys
        invoice_id,

        -- Foreign keys
        customer_id,
        household_id,
        contract_id,

        -- Attributes
        CAST(invoice_date AS DATE) AS invoice_date,
        CAST(due_date AS DATE) AS due_date,
        CAST(total_amount AS NUMBER(12, 2)) AS total_amount,
        CAST(tax_amount AS NUMBER(12, 2)) AS tax_amount,
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
