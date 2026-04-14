WITH source AS (
    SELECT * FROM {{ source('crm', 'contacts') }}
),

filtered AS (
    SELECT *
    FROM source
    WHERE _is_deleted = FALSE
),

renamed AS (
    SELECT
        -- Keys
        contact_id,

        -- Foreign keys
        account_id,

        -- Attributes
        first_name,
        last_name,
        LOWER(email) AS email,
        phone,
        title,
        department,
        CAST(created_date AS DATE) AS created_date,
        CAST(last_modified_date AS DATE) AS last_modified_date,

        -- Metadata
        _loaded_at,
        _sync_id

    FROM filtered
)

SELECT * FROM renamed
