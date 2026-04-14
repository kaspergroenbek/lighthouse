WITH source AS (
    SELECT * FROM {{ source('partner_feeds', 'product_catalog_updates') }}
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY effective_date DESC
        ) AS _row_num
    FROM source
),

renamed AS (
    SELECT
        -- Keys
        product_id,
        CAST(effective_date AS DATE) AS effective_date,

        -- Attributes
        product_name,
        category,
        manufacturer,
        model_number,
        specifications,
        list_price::NUMBER(12,2) AS list_price,
        is_discontinued,

        -- Metadata
        _loaded_at,
        _source_file_name,
        _source_file_row_number

    FROM deduplicated
    WHERE _row_num = 1
)

SELECT * FROM renamed
