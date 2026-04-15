-- Convenience entrypoint for PROD raw bootstrap.
-- Run with:
--   EXECUTE IMMEDIATE FROM @repo_clone/branches/<branch>/snowflake/orchestration/load_raw_prod.sql
--   USING (repo_root => '@repo_clone/branches/<branch>');
EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/orchestration/load_raw.sql
  USING (env => 'PROD', repo_root => '{{ repo_root }}');
