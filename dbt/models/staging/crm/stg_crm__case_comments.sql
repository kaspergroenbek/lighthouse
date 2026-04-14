WITH source AS (
    SELECT * FROM {{ source('crm', 'case_comments') }}
),

filtered AS (
    SELECT *
    FROM source
    WHERE _is_deleted = FALSE
),

renamed AS (
    SELECT
        -- Keys
        comment_id,

        -- Foreign keys
        case_id,

        -- Attributes
        body,
        is_public,
        created_by,
        CAST(created_date AS DATE) AS created_date,

        -- Metadata
        _loaded_at,
        _sync_id

    FROM filtered
)

SELECT * FROM renamed
