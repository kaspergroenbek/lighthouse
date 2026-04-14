-- =============================================================================
-- 02_warehouses.sql — Create Lighthouse compute warehouses
-- =============================================================================
-- Purpose:  Provisions four warehouses sized and configured per workload type.
--           All warehouses start suspended and auto-resume on first query.
--
-- Idempotency: Uses CREATE WAREHOUSE IF NOT EXISTS — safe to re-run.
-- =============================================================================

-- Ingestion warehouse — COPY INTO, seed loading, lightweight ingestion tasks
CREATE WAREHOUSE IF NOT EXISTS INGESTION_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Lighthouse ingestion workloads — COPY INTO, seed loading';

-- Transform warehouse — dbt build (staging, intermediate, marts)
CREATE WAREHOUSE IF NOT EXISTS TRANSFORM_WH
    WITH WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Lighthouse transformation workloads — dbt build';

-- Serving warehouse — Streamlit queries, BI tool queries, Dynamic Table refresh
CREATE WAREHOUSE IF NOT EXISTS SERVING_WH
    WITH WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Lighthouse serving workloads — Streamlit, BI queries, Dynamic Tables';

-- AI warehouse — Cortex Analyst, Cortex Search, ML workloads
CREATE WAREHOUSE IF NOT EXISTS AI_WH
    WITH WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Lighthouse AI workloads — Cortex Analyst, Cortex Search';
