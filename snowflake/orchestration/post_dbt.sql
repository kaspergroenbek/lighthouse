-- =============================================================================
-- Orchestration: Post-dbt Snowflake Assets
-- Run after dbt Cloud build succeeds.
-- =============================================================================

EXECUTE IMMEDIATE FROM '../semantic/contract_revenue_semantic.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../cortex/cortex_search_service.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../governance/tags.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../governance/masking_policies.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../governance/row_access_policies.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../governance/apply_policies.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../serving/device_latest_status.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM '../monitoring/test_alert_task.sql' USING (env => '{{ env }}');
