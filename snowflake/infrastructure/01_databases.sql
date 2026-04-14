-- =============================================================================
-- 01_databases.sql — Create Lighthouse databases per environment and layer
-- =============================================================================
-- Provisions the three logical-layer databases for a given environment.
-- Databases follow the naming convention LIGHTHOUSE_{ENV}_{LAYER}.
--
-- Usage:    Run standalone or via deploy.sql. Change 'DEV' below as needed.
-- Idempotency: Uses CREATE DATABASE IF NOT EXISTS — safe to re-run.
-- =============================================================================

DECLARE
    env VARCHAR DEFAULT 'DEV';
BEGIN
    EXECUTE IMMEDIATE 'CREATE DATABASE IF NOT EXISTS LIGHTHOUSE_' || :env || '_RAW';
    EXECUTE IMMEDIATE 'CREATE DATABASE IF NOT EXISTS LIGHTHOUSE_' || :env || '_ANALYTICS';
    EXECUTE IMMEDIATE 'CREATE DATABASE IF NOT EXISTS LIGHTHOUSE_' || :env || '_SERVING';
    RETURN 'Databases created for environment: ' || :env;
END;
