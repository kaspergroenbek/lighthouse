WITH source AS (
    SELECT * FROM {{ source('crm', 'accounts') }}
),

filtered AS (
    SELECT *
    FROM source
    WHERE _is_deleted = FALSE
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY account_id
            ORDER BY
                last_modified_date DESC NULLS LAST,
                _loaded_at DESC NULLS LAST,
                _sync_id DESC NULLS LAST
        ) AS _row_num
    FROM filtered
),

renamed AS (
    SELECT
        -- Keys
        account_id,

        -- Attributes
        account_name,
        industry,
        website,
        phone,
        billing_address,
        region,
        owner_id,
        CAST(created_date AS DATE) AS created_date,
        CAST(last_modified_date AS DATE) AS last_modified_date,

        -- Metadata
        _loaded_at,
        _sync_id

    FROM deduplicated
    WHERE _row_num = 1
)

SELECT * FROM renamed
