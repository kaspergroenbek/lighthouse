-- Convenience entrypoint for DEV raw bootstrap.
EXECUTE IMMEDIATE FROM {{ repo_root }}/snowflake/orchestration/load_raw.sql
  USING (env => 'DEV', repo_root => '{{ repo_root }}');
