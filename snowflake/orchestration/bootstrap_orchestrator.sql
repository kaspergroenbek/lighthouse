-- =============================================================================
-- Bootstrap Orchestrator
-- Preferred top-level entrypoint for raw data bootstrap from a Snowflake
-- Git repository clone.
--
-- Run with:
-- EXECUTE IMMEDIATE FROM @<db>.<schema>.<repo_clone>/branches/<branch>/snowflake/orchestration/bootstrap_orchestrator.sql
-- USING (
--   env => 'PROD',
--   repo_root => '@<db>.<schema>.<repo_clone>/branches/<branch>'
-- );
-- =============================================================================

EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/orchestration/load_raw.sql
USING (
  env => '{{ env }}',
  repo_root => '{{ repo_root }}'
);
