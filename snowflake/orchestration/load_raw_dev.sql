-- Convenience entrypoint for DEV raw bootstrap.
EXECUTE IMMEDIATE FROM './load_raw.sql' USING (env => 'DEV');
