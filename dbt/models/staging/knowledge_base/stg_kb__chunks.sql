WITH source AS (
    SELECT * FROM {{ source('knowledge_base', 'document_chunks') }}
),

documents AS (
    SELECT
        document_id,
        file_name AS document_title,
        category AS document_category
    FROM {{ source('knowledge_base', 'documents') }}
),

renamed AS (
    SELECT
        -- Keys
        source.chunk_id,
        source.document_id,

        -- Attributes
        source.chunk_sequence_number,
        source.chunk_text,
        documents.document_title,
        documents.document_category,

        -- Metadata
        source._chunked_at

    FROM source
    LEFT JOIN documents
        ON source.document_id = documents.document_id
)

SELECT * FROM renamed
