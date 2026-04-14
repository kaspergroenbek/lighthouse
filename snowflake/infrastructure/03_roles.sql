-- =============================================================================
-- 03_roles.sql — Create Lighthouse role hierarchy
-- =============================================================================
-- Purpose:  Provisions the four-tier role hierarchy following Snowflake's
--           recommended pattern. Each role inherits privileges from the role
--           below it in the hierarchy:
--
--           SYSADMIN
--             └── LIGHTHOUSE_ADMIN
--                   └── LIGHTHOUSE_ENGINEER
--                         └── LIGHTHOUSE_TRANSFORMER
--                               └── LIGHTHOUSE_READER
--
-- Idempotency: Uses CREATE ROLE IF NOT EXISTS and GRANT ROLE — safe to re-run.
-- =============================================================================

-- Create roles (bottom-up)
CREATE ROLE IF NOT EXISTS LIGHTHOUSE_READER
    COMMENT = 'Read-only access to analytics and serving data products';

CREATE ROLE IF NOT EXISTS LIGHTHOUSE_TRANSFORMER
    COMMENT = 'dbt transformation role — can create/modify objects in analytics schemas';

CREATE ROLE IF NOT EXISTS LIGHTHOUSE_ENGINEER
    COMMENT = 'Data engineering role — full access to all databases and warehouses';

CREATE ROLE IF NOT EXISTS LIGHTHOUSE_ADMIN
    COMMENT = 'Platform admin role — manages grants, databases, and platform configuration';

-- Establish role hierarchy (each role inherits from the one below)
GRANT ROLE LIGHTHOUSE_READER TO ROLE LIGHTHOUSE_TRANSFORMER;
GRANT ROLE LIGHTHOUSE_TRANSFORMER TO ROLE LIGHTHOUSE_ENGINEER;
GRANT ROLE LIGHTHOUSE_ENGINEER TO ROLE LIGHTHOUSE_ADMIN;

-- Connect to Snowflake's built-in hierarchy
GRANT ROLE LIGHTHOUSE_ADMIN TO ROLE SYSADMIN;
