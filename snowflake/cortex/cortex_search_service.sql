-- =============================================================================
-- Cortex Search Service: Knowledge Base
-- Enables semantic search over chunked knowledge base documents
-- =============================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE
    LIGHTHOUSE_PROD_ANALYTICS.MARTS.knowledge_search_service
  ON chunk_text
  ATTRIBUTES document_category, document_title
  WAREHOUSE = AI_WH
  TARGET_LAG = '24 hours'
  AS (
    SELECT
        chunk_id,
        document_id,
        chunk_sequence_number,
        chunk_text,
        document_title,
        document_category,
        source_file_name
    FROM LIGHTHOUSE_PROD_ANALYTICS.MARTS.knowledge_chunks
  );

-- =============================================================================
-- Example Search Queries
-- =============================================================================

-- Example 1: Find thermostat troubleshooting steps
-- SELECT *
-- FROM TABLE(
--     LIGHTHOUSE_PROD_ANALYTICS.MARTS.knowledge_search_service!SEARCH(
--         query => 'thermostat not heating properly',
--         columns => ['chunk_text', 'document_title', 'document_category'],
--         filter => {'@eq': {'document_category': 'support_article'}},
--         limit => 5
--     )
-- );

-- Example 2: Find firmware update procedures
-- SELECT *
-- FROM TABLE(
--     LIGHTHOUSE_PROD_ANALYTICS.MARTS.knowledge_search_service!SEARCH(
--         query => 'how to update device firmware',
--         columns => ['chunk_text', 'document_title'],
--         filter => {'@eq': {'document_category': 'procedure'}},
--         limit => 3
--     )
-- );

-- Example 3: Find energy meter installation instructions
-- SELECT *
-- FROM TABLE(
--     LIGHTHOUSE_PROD_ANALYTICS.MARTS.knowledge_search_service!SEARCH(
--         query => 'energy meter installation steps',
--         columns => ['chunk_text', 'document_title', 'document_category'],
--         limit => 5
--     )
-- );
