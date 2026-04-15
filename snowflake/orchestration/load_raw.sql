-- =============================================================================
-- Orchestration: Raw Data Bootstrap
-- Run with EXECUTE IMMEDIATE FROM and pass env => 'DEV' | 'STAGING' | 'PROD'
-- =============================================================================

EXECUTE IMMEDIATE FROM '../ingestion_web/load_oltp_seeds.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../ingestion_web/load_crm_seeds.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../ingestion_web/load_iot_seeds.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../ingestion_web/load_partner_feeds.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../ingestion_web/load_knowledge_base.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../ingestion_web/chunk_documents.sql' USING (env => '{{ env }}');
