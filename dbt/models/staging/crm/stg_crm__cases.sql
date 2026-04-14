WITH source AS (
    SELECT * FROM {{ source('crm', 'cases') }}
),

filtered AS (
    SELECT *
    FROM source
    WHERE _is_deleted = FALSE
),

renamed AS (
    SELECT
        -- Keys
        case_id,

        -- Foreign keys
        account_id,
        contact_id,

        -- Attributes
        subject,
        description,
        status,
        priority,
        severity,
        origin,
        CAST(created_date AS DATE) AS created_date,
        CAST(closed_date AS DATE) AS closed_date,
        CAST(last_modified_date AS DATE) AS last_modified_date,

        -- Metadata
        _loaded_at,
        _sync_id

    FROM filtered
)

SELECT * FROM renamed
