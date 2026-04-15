-- Use this bootstrap orchestrator to specify enironment and load script.
EXECUTE IMMEDIATE FROM @INTEGRATIONS_DB.GIT.LIGHTHOUSE_REPO/branches/main/snowflake/orchestration/load_raw.sql
USING (
  env => 'PROD',
  repo_root => '@INTEGRATIONS_DB.GIT.LIGHTHOUSE_REPO/branches/main'
);
