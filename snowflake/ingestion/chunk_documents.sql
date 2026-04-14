-- =============================================================================
-- chunk_documents.sql — Stored procedure to extract text and chunk documents
-- =============================================================================
-- Purpose:  Creates a stored procedure that reads extracted text from the
--           document_text table, chunks it into ~512 token segments with
--           ~50 token overlap, and inserts chunks into document_chunks.
--           Also creates an error logging table for failed extractions.
--
-- Prerequisites:
--   - load_knowledge_base.sql (documents, document_text, document_chunks tables)
--
-- Chunking strategy:
--   - Target chunk size: ~512 tokens ≈ 2048 characters
--   - Overlap: ~50 tokens ≈ 200 characters
--   - Chunks are created by splitting on character boundaries
--   - Each chunk gets a sequential ID within its document
--
-- Idempotency: Uses CREATE OR REPLACE — safe to re-run.
-- =============================================================================

USE WAREHOUSE INGESTION_WH;
USE DATABASE LIGHTHOUSE_DEV_RAW;
USE SCHEMA KNOWLEDGE_BASE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. ERROR LOGGING TABLE
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE TABLE document_processing_errors (
    document_id     VARCHAR(50)         COMMENT 'Document that failed processing',
    error_type      VARCHAR(100)        COMMENT 'Error classification: extraction_error, chunking_error',
    error_message   VARCHAR(4000)       COMMENT 'Detailed error message',
    logged_at       TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP() COMMENT 'Error timestamp'
)
COMMENT = 'Error log for document text extraction and chunking failures';


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. STORED PROCEDURE — chunk_document_text()
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE PROCEDURE chunk_document_text()
    RETURNS VARCHAR
    LANGUAGE JAVASCRIPT
    EXECUTE AS CALLER
    COMMENT = 'Chunks extracted document text into ~512 token segments with ~50 token overlap'
AS
$$
    var CHUNK_SIZE = 2048;   // ~512 tokens ≈ 2048 characters
    var OVERLAP    = 200;    // ~50 tokens  ≈ 200 characters
    var totalChunks = 0;
    var errorCount  = 0;

    // Clear existing chunks for idempotent re-runs
    snowflake.execute({sqlText: "DELETE FROM document_chunks"});

    // Fetch all documents with extracted text
    var docQuery = snowflake.execute({
        sqlText: "SELECT document_id, extracted_text FROM document_text WHERE extracted_text IS NOT NULL"
    });

    while (docQuery.next()) {
        var docId = docQuery.getColumnValue(1);
        var text  = docQuery.getColumnValue(2);

        try {
            if (!text || text.length === 0) {
                snowflake.execute({
                    sqlText: "INSERT INTO document_processing_errors (document_id, error_type, error_message) " +
                             "VALUES (?, 'extraction_error', 'Document has empty or null extracted text')",
                    binds: [docId]
                });
                errorCount++;
                continue;
            }

            var chunkSeq = 0;
            var startPos = 0;

            while (startPos < text.length) {
                chunkSeq++;
                var endPos = Math.min(startPos + CHUNK_SIZE, text.length);

                // Try to break at a natural boundary near the end of the chunk
                if (endPos < text.length) {
                    var searchStart = Math.max(endPos - 100, startPos);
                    var segment = text.substring(searchStart, endPos);

                    // Prefer paragraph boundary (double newline)
                    var paraBreak = segment.lastIndexOf("\n\n");
                    if (paraBreak > 0) {
                        endPos = searchStart + paraBreak + 2;
                    } else {
                        // Fall back to sentence boundary (period + space)
                        var sentBreak = segment.lastIndexOf(". ");
                        if (sentBreak > 0) {
                            endPos = searchStart + sentBreak + 2;
                        }
                    }
                }

                var chunkText = text.substring(startPos, endPos);
                var chunkId = docId + '-' + ('00' + chunkSeq).slice(-3);

                snowflake.execute({
                    sqlText: "INSERT INTO document_chunks (chunk_id, document_id, chunk_sequence_number, chunk_text) " +
                             "VALUES (?, ?, ?, ?)",
                    binds: [chunkId, docId, chunkSeq, chunkText]
                });

                totalChunks++;

                // Advance with overlap
                if (endPos >= text.length) {
                    break;
                }
                startPos = Math.max(endPos - OVERLAP, startPos + 1);
            }

        } catch (err) {
            snowflake.execute({
                sqlText: "INSERT INTO document_processing_errors (document_id, error_type, error_message) " +
                         "VALUES (?, 'chunking_error', ?)",
                binds: [docId, err.message]
            });
            errorCount++;
        }
    }

    return 'Chunking complete. Total chunks created: ' + totalChunks + '. Errors: ' + errorCount;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. EXECUTE — Run the chunking procedure
-- ─────────────────────────────────────────────────────────────────────────────

CALL chunk_document_text();
