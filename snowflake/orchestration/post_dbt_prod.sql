-- Convenience entrypoint for PROD post-dbt assets.
-- Run with:
--   EXECUTE IMMEDIATE FROM @repo_clone/branches/<branch>/snowflake/orchestration/post_dbt_prod.sql
--   USING (repo_root => '@repo_clone/branches/<branch>');
EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/orchestration/post_dbt.sql
  USING (env => 'PROD', repo_root => '{{ repo_root }}');
