-- =============================================================================
-- Orchestration: Post-dbt Snowflake Assets
-- Run with EXECUTE IMMEDIATE FROM and pass:
--   env => 'DEV' | 'STAGING' | 'PROD'
--   repo_root => '@repo_clone/branches/<branch>'
-- =============================================================================

EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/semantic/contract_revenue_semantic.sql
  USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/serving/device_latest_status.sql
  USING (env => '{{ env }}');
