WITH source AS (
    SELECT * FROM {{ source('crm', 'accounts') }}
),

filtered AS (
    SELECT *
    FROM source
    WHERE _is_deleted = FALSE
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

    FROM filtered
)

SELECT * FROM renamed
