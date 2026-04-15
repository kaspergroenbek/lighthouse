-- Convenience entrypoint for DEV post-dbt assets.
EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/orchestration/post_dbt.sql
  USING (env => 'DEV', repo_root => '{{ repo_root }}');
