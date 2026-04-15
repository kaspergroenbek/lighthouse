-- Convenience entrypoint for PROD raw bootstrap.
EXECUTE IMMEDIATE FROM './load_raw.sql' USING (env => 'PROD');
