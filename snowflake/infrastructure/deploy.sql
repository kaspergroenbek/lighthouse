-- =============================================================================
-- deploy.sql — Orchestration script for Lighthouse infrastructure deployment
-- =============================================================================
-- Purpose:  Executes all infrastructure scripts (01–08) in dependency order
--           to provision a complete Lighthouse environment.
--
-- Usage:
--   Snowflake worksheet (recommended):
--     1. Change the env variable below to your target (DEV, STAGING, or PROD)
--     2. Select all and run — sub-scripts inherit the env variable
--
--   SnowSQL CLI (note: !source requires SnowSQL, not standard SQL):
--     snowsql -c lighthouse -f snowflake/infrastructure/deploy.sql
--
-- Execution order (dependency-driven):
--   01_databases.sql    — Databases must exist before schemas, stages, formats
--   02_warehouses.sql   — Warehouses are independent of databases
--   03_roles.sql        — Roles must exist before grants
--   04_grants.sql       — Requires databases, warehouses, and roles
--   05_schemas.sql      — Requires databases
--   06_stages.sql       — Requires databases and schemas
--   07_integrations.sql — Requires roles (for grant targets)
--   08_file_formats.sql — Requires databases and schemas
--
-- Idempotency: All sub-scripts use CREATE IF NOT EXISTS or CREATE OR REPLACE.
--              This deploy script can be executed repeatedly without error.
--
-- Environment: Override the env variable for different target environments.
--              Valid values: DEV, STAGING, PROD
-- =============================================================================

-- Set the target environment (change this to STAGING or PROD as needed)
SET env = 'DEV';

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 1: Create databases
-- ─────────────────────────────────────────────────────────────────────────────
!source snowflake/infrastructure/01_databases.sql;

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 2: Create warehouses
-- ─────────────────────────────────────────────────────────────────────────────
!source snowflake/infrastructure/02_warehouses.sql;

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 3: Create roles
-- ─────────────────────────────────────────────────────────────────────────────
!source snowflake/infrastructure/03_roles.sql;

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 4: Grant privileges
-- ─────────────────────────────────────────────────────────────────────────────
!source snowflake/infrastructure/04_grants.sql;

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 5: Create schemas
-- ─────────────────────────────────────────────────────────────────────────────
!source snowflake/infrastructure/05_schemas.sql;

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 6: Create internal stages
-- ─────────────────────────────────────────────────────────────────────────────
!source snowflake/infrastructure/06_stages.sql;

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 7: Create integrations (templates — commented out for trial accounts)
-- ─────────────────────────────────────────────────────────────────────────────
!source snowflake/infrastructure/07_integrations.sql;

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 8: Create file formats
-- ─────────────────────────────────────────────────────────────────────────────
!source snowflake/infrastructure/08_file_formats.sql;

-- ─────────────────────────────────────────────────────────────────────────────
-- Deployment complete
-- ─────────────────────────────────────────────────────────────────────────────
SELECT 'Lighthouse infrastructure deployment complete for environment: ' || $env AS deployment_status;
