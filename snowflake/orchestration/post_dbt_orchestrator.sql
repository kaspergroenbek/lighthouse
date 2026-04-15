-- =============================================================================
-- Post-dbt Orchestrator
-- Preferred top-level entrypoint for Snowflake-native assets that should run
-- after dbt Cloud has successfully built the analytics layer.
--
-- Run with:
-- EXECUTE IMMEDIATE FROM @<db>.<schema>.<repo_clone>/branches/<branch>/snowflake/orchestration/post_dbt_orchestrator.sql
-- USING (
--   env => 'PROD',
--   repo_root => '@<db>.<schema>.<repo_clone>/branches/<branch>'
-- );
-- =============================================================================

EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/orchestration/post_dbt.sql
USING (
  env => '{{ env }}',
  repo_root => '{{ repo_root }}'
);
