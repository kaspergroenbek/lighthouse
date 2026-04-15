-- =============================================================================
-- Orchestration: Post-dbt Snowflake Assets
-- Run with EXECUTE IMMEDIATE FROM and pass:
--   env => 'DEV' | 'STAGING' | 'PROD'
--   repo_root => '@repo_clone/branches/<branch>'
-- =============================================================================

EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/semantic/contract_revenue_semantic.sql
  USING (env => '{{ env }}');
EXECUTE IMMEDIATE $$
BEGIN
  EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/cortex/cortex_search_service.sql
    USING (env => '{{ env }}');
  RETURN 'Cortex Search service deployed';
EXCEPTION
  WHEN STATEMENT_ERROR THEN
    RETURN 'Cortex Search skipped: account does not currently accept CREATE CORTEX SEARCH SERVICE';
END;
$$;
EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/governance/tags.sql
  USING (env => '{{ env }}');
EXECUTE IMMEDIATE $$
BEGIN
  EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/governance/masking_policies.sql
    USING (env => '{{ env }}');
  RETURN 'Masking policies deployed';
EXCEPTION
  WHEN STATEMENT_ERROR THEN
    RETURN 'Masking policies skipped: account does not currently support MASKING POLICY';
END;
$$;
EXECUTE IMMEDIATE $$
BEGIN
  EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/governance/row_access_policies.sql
    USING (env => '{{ env }}');
  RETURN 'Row access policies deployed';
EXCEPTION
  WHEN STATEMENT_ERROR THEN
    RETURN 'Row access policies skipped: account does not currently support ROW ACCESS POLICY';
END;
$$;
EXECUTE IMMEDIATE $$
BEGIN
  EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/governance/apply_policies.sql
    USING (env => '{{ env }}');
  RETURN 'Governance policies applied';
EXCEPTION
  WHEN STATEMENT_ERROR THEN
    RETURN 'Governance policy application skipped: dependent governance features are not available';
END;
$$;
EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/serving/device_latest_status.sql
  USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/monitoring/test_alert_task.sql
  USING (env => '{{ env }}');
