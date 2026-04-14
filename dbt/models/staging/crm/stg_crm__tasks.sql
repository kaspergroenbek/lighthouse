WITH source AS (
    SELECT * FROM {{ source('crm', 'tasks') }}
),

filtered AS (
    SELECT *
    FROM source
    WHERE _is_deleted = FALSE
),

renamed AS (
    SELECT
        -- Keys
        task_id,

        -- Foreign keys
        account_id,
        contact_id,

        -- Attributes
        subject,
        status,
        priority,
        CAST(due_date AS DATE) AS due_date,
        CAST(completed_date AS DATE) AS completed_date,
        CAST(created_date AS DATE) AS created_date,

        -- Metadata
        _loaded_at,
        _sync_id

    FROM filtered
)

SELECT * FROM renamed
