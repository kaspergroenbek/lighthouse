-- =============================================================================
-- load_knowledge_base.sql — Create knowledge base tables and load documents
-- =============================================================================
-- Purpose:  Creates raw tables in RAW.KNOWLEDGE_BASE for document tracking,
--           extracted text, and chunked content. Loads synthetic Markdown
--           documents via PUT and registers them in the tracking table.
--
-- Prerequisites:
--   - 01_databases.sql  (LIGHTHOUSE_{ENV}_RAW database)
--   - 05_schemas.sql    (RAW.KNOWLEDGE_BASE schema)
--   - 06_stages.sql     (@RAW.KNOWLEDGE_BASE.kb_stage)
--
-- Tables:
--   documents       — Document tracking/metadata registry
--   document_text   — Extracted text content per document
--   document_chunks — Chunked text segments for search indexing
--
-- Note: In the demo environment, text extraction reads Markdown content
--       directly. In production, PARSE_DOCUMENT would handle binary PDFs.
--
-- Idempotency: Uses CREATE OR REPLACE TABLE and DELETE+INSERT — safe to re-run.
-- =============================================================================

SET env = 'PROD';

USE WAREHOUSE INGESTION_WH;
USE DATABASE IDENTIFIER('LIGHTHOUSE_' || $env || '_RAW');
USE SCHEMA KNOWLEDGE_BASE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. RAW TABLE DDL
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE TABLE documents (
    document_id     VARCHAR(50)         COMMENT 'Natural key — document identifier',
    file_name       VARCHAR(255)        COMMENT 'Original file name',
    file_type       VARCHAR(20)         COMMENT 'File type: markdown, text',
    source_path     VARCHAR(500)        COMMENT 'Source file path in stage',
    category        VARCHAR(50)         COMMENT 'Category: manual, procedure, policy, support_article',
    _loaded_at      TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp'
)
COMMENT = 'Document tracking table for NordHjem knowledge base';

CREATE OR REPLACE TABLE document_text (
    document_id     VARCHAR(50)         COMMENT 'FK to documents',
    extracted_text  VARCHAR(16777216)   COMMENT 'Full extracted text content',
    _extracted_at   TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP() COMMENT 'Text extraction timestamp'
)
COMMENT = 'Extracted text content from knowledge base documents';

CREATE OR REPLACE TABLE document_chunks (
    chunk_id                VARCHAR(50)         COMMENT 'Natural key — chunk identifier',
    document_id             VARCHAR(50)         COMMENT 'FK to documents',
    chunk_sequence_number   INTEGER             COMMENT 'Chunk sequence within document (1-based)',
    chunk_text              VARCHAR(16777216)   COMMENT 'Chunked text segment (~512 tokens)',
    _chunked_at             TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP() COMMENT 'Chunking timestamp'
)
COMMENT = 'Chunked document text for search indexing and embedding';


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. PUT — Upload Markdown documents to internal stage
-- ─────────────────────────────────────────────────────────────────────────────

PUT file://data/knowledge_base/manual_energy_meter_pro.md          @kb_stage/documents/ AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/knowledge_base/manual_smart_thermostat_v2.md       @kb_stage/documents/ AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/knowledge_base/policy_data_retention.md            @kb_stage/documents/ AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/knowledge_base/procedure_device_installation.md    @kb_stage/documents/ AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/knowledge_base/procedure_firmware_update.md        @kb_stage/documents/ AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/knowledge_base/support_connectivity_issues.md      @kb_stage/documents/ AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT file://data/knowledge_base/support_thermostat_troubleshooting.md @kb_stage/documents/ AUTO_COMPRESS = TRUE OVERWRITE = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. INSERT — Register documents in tracking table with metadata
-- ─────────────────────────────────────────────────────────────────────────────
-- Since these are Markdown files (not tabular data), we register them manually
-- with metadata rather than using COPY INTO.

INSERT INTO documents (document_id, file_name, file_type, source_path, category)
VALUES
    ('DOC-001', 'manual_energy_meter_pro.md',          'markdown', '@kb_stage/documents/manual_energy_meter_pro.md.gz',          'manual'),
    ('DOC-002', 'manual_smart_thermostat_v2.md',       'markdown', '@kb_stage/documents/manual_smart_thermostat_v2.md.gz',       'manual'),
    ('DOC-003', 'policy_data_retention.md',            'markdown', '@kb_stage/documents/policy_data_retention.md.gz',            'policy'),
    ('DOC-004', 'procedure_device_installation.md',    'markdown', '@kb_stage/documents/procedure_device_installation.md.gz',    'procedure'),
    ('DOC-005', 'procedure_firmware_update.md',        'markdown', '@kb_stage/documents/procedure_firmware_update.md.gz',        'procedure'),
    ('DOC-006', 'support_connectivity_issues.md',      'markdown', '@kb_stage/documents/support_connectivity_issues.md.gz',      'support_article'),
    ('DOC-007', 'support_thermostat_troubleshooting.md','markdown','@kb_stage/documents/support_thermostat_troubleshooting.md.gz','support_article');
