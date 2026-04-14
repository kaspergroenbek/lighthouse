WITH source AS (
    SELECT * FROM {{ source('knowledge_base', 'documents') }}
),

renamed AS (
    SELECT
        -- Keys
        document_id,

        -- Attributes
        file_name,
        file_type,
        source_path,
        category,

        -- Metadata
        _loaded_at

    FROM source
)

SELECT * FROM renamed
