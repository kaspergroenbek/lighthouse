WITH source AS (
    SELECT * FROM {{ source('crm', 'campaign_members') }}
),

filtered AS (
    SELECT *
    FROM source
    WHERE _is_deleted = FALSE
),

renamed AS (
    SELECT
        -- Keys
        member_id,

        -- Foreign keys
        campaign_id,
        contact_id,

        -- Attributes
        status,
        CAST(first_responded_date AS DATE) AS first_responded_date,
        CAST(created_date AS DATE) AS created_date,

        -- Metadata
        _loaded_at,
        _sync_id

    FROM filtered
)

SELECT * FROM renamed
