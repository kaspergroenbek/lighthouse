WITH source AS (
    SELECT * FROM {{ source('crm', 'opportunities') }}
),

filtered AS (
    SELECT *
    FROM source
    WHERE _is_deleted = FALSE
),

renamed AS (
    SELECT
        -- Keys
        opportunity_id,

        -- Foreign keys
        account_id,

        -- Attributes
        name,
        stage,
        CAST(amount AS NUMBER(12, 2)) AS amount,
        CAST(close_date AS DATE) AS close_date,
        probability,
        CAST(created_date AS DATE) AS created_date,
        CAST(last_modified_date AS DATE) AS last_modified_date,

        -- Metadata
        _loaded_at,
        _sync_id

    FROM filtered
)

SELECT * FROM renamed
