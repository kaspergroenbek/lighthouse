-- Convenience entrypoint for PROD post-dbt assets.
EXECUTE IMMEDIATE FROM './post_dbt.sql' USING (env => 'PROD');
