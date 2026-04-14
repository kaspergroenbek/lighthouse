WITH source AS (
    SELECT * FROM {{ source('crm', 'campaigns') }}
),

filtered AS (
    SELECT *
    FROM source
    WHERE _is_deleted = FALSE
),

renamed AS (
    SELECT
        -- Keys
        campaign_id,

        -- Attributes
        name,
        type,
        status,
        CAST(start_date AS DATE) AS start_date,
        CAST(end_date AS DATE) AS end_date,
        CAST(budget AS NUMBER(12, 2)) AS budget,
        CAST(actual_cost AS NUMBER(12, 2)) AS actual_cost,
        CAST(created_date AS DATE) AS created_date,

        -- Metadata
        _loaded_at,
        _sync_id

    FROM filtered
)

SELECT * FROM renamed
