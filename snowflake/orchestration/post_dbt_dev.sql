-- Convenience entrypoint for DEV post-dbt assets.
EXECUTE IMMEDIATE FROM './post_dbt.sql' USING (env => 'DEV');
