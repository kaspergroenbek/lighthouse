-- =============================================================================
-- Cortex Search Service: Knowledge Base
-- Enables semantic search over chunked knowledge base documents
-- =============================================================================

SET LIGHTHOUSE_ENV = '{{ env }}';
SET LIGHTHOUSE_ANALYTICS_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_ANALYTICS';

EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_ANALYTICS_DB;
USE SCHEMA MARTS;

CREATE OR REPLACE CORTEX SEARCH SERVICE knowledge_search_service
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
    FROM knowledge_chunks
  );

