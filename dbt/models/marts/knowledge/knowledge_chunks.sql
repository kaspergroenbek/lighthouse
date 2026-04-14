WITH chunks AS (
    SELECT * FROM {{ ref('stg_kb__chunks') }}
),

documents AS (
    SELECT * FROM {{ ref('stg_kb__documents') }}
),

final AS (
    SELECT
        chunks.chunk_id,
        chunks.document_id,
        chunks.chunk_sequence_number,
        chunks.chunk_text,
        chunks.document_title,
        chunks.document_category,
        documents.file_name AS source_file_name,
        documents._loaded_at
    FROM chunks
    LEFT JOIN documents ON chunks.document_id = documents.document_id
)

SELECT * FROM final
