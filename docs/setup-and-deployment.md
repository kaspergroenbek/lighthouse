# Lighthouse Setup & Deployment Guide

Step-by-step guide to get the Lighthouse data platform running end-to-end on Snowflake and dbt.

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Snowflake account | Standard Edition or higher | Data warehouse |
| SnowSQL CLI | Latest | Run SQL scripts against Snowflake |
| Python | 3.11+ | dbt runtime |
| pip | Latest | Install dbt |
| Git | Latest | Version control |
| GitHub account | — | CI/CD pipelines (optional for local-only) |

### Install SnowSQL

Download from [Snowflake's SnowSQL page](https://docs.snowflake.com/en/user-guide/snowsql-install-config). After install, configure your connection:

```ini
# ~/.snowsql/config
[connections.lighthouse]
accountname = <your_account_identifier>
username = <your_username>
password = <your_password>
rolename = ACCOUNTADMIN
warehousename = COMPUTE_WH
```

You'll use `ACCOUNTADMIN` for the initial infrastructure deployment, then switch to `LIGHTHOUSE_ENGINEER` for day-to-day work.

### Install dbt

```bash
pip install dbt-snowflake
dbt --version   # confirm installation
```

---

## Phase 1: Repository Setup

### Option A: Single repo (recommended for getting started)

Clone or fork this repository as-is. Everything lives in one repo:

```bash
git clone <your-repo-url> lighthouse
cd lighthouse
```

### Option B: Separate repos (for team environments)

If you want to split concerns:

| Repo | Contents | Who owns it |
|------|----------|-------------|
| `lighthouse-infra` | `snowflake/` — infrastructure, ingestion, governance, monitoring | Platform / DevOps team |
| `lighthouse-dbt` | `dbt/` — models, tests, snapshots, seeds, macros | Analytics engineering team |
| `lighthouse-app` | `streamlit/` — Streamlit in Snowflake app | App / product team |
| `lighthouse-data` | `data/` — synthetic seed data files | Shared / referenced by infra repo |

For the split approach, move the relevant directories into their own repos and update file paths in the SQL scripts (the `PUT file://` paths reference `data/` relative to where SnowSQL runs).

This guide assumes the single-repo approach.

---

## Phase 2: Snowflake Infrastructure

All infrastructure scripts are idempotent — you can re-run them safely.

### Step 2.1: Choose your target environment

```
DEV      → LIGHTHOUSE_DEV_*       (local development)
STAGING  → LIGHTHOUSE_STAGING_*   (CI validation)
PROD     → LIGHTHOUSE_PROD_*      (production)
```

For first-time setup, use `DEV`.

### Step 2.2: Deploy infrastructure

Run the orchestration script. This executes scripts 01–08 in dependency order:

```bash
snowsql -c lighthouse -f snowflake/infrastructure/deploy.sql -D env=DEV
```

This creates:
- 3 databases: `LIGHTHOUSE_DEV_RAW`, `LIGHTHOUSE_DEV_ANALYTICS`, `LIGHTHOUSE_DEV_SERVING`
- 4 warehouses: `INGESTION_WH` (XS), `TRANSFORM_WH` (S), `SERVING_WH` (S), `AI_WH` (M)
- 4 roles: `LIGHTHOUSE_READER` → `TRANSFORMER` → `ENGINEER` → `ADMIN`
- All schemas, internal stages, and file formats


**If `deploy.sql` doesn't work** (the `!source` command requires SnowSQL), run each script individually:

| Script | Purpose |
|--------|---------|
| `01_databases.sql` | Create databases (`RAW`, `ANALYTICS`, `SERVING`) |
| `02_warehouses.sql` | Create and configure warehouses |
| `03_roles.sql` | Create role hierarchy (`ADMIN` → `ENGINEER` → `TRANSFORMER` → `READER`) |
| `04_grants.sql` | Database, schema, table, and warehouse grants per role |
| `05_schemas.sql` | All schemas per the layout (OLTP, CRM, IOT, STAGING, MARTS, etc.) |
| `06_stages.sql` | Internal stages per source for data loading |
| `07_integrations.sql` | Storage/API integration templates (commented out for trial accounts) |
| `08_file_formats.sql` | CSV, Parquet, and JSON file format objects per source |

```bash
snowsql -c lighthouse -f snowflake/infrastructure/01_databases.sql -D env=DEV
snowsql -c lighthouse -f snowflake/infrastructure/02_warehouses.sql
snowsql -c lighthouse -f snowflake/infrastructure/03_roles.sql
snowsql -c lighthouse -f snowflake/infrastructure/04_grants.sql -D env=DEV
snowsql -c lighthouse -f snowflake/infrastructure/05_schemas.sql -D env=DEV
snowsql -c lighthouse -f snowflake/infrastructure/06_stages.sql -D env=DEV
snowsql -c lighthouse -f snowflake/infrastructure/07_integrations.sql
snowsql -c lighthouse -f snowflake/infrastructure/08_file_formats.sql -D env=DEV
```

### Step 2.3: Grant your user the LIGHTHOUSE_ENGINEER role

Run as `ACCOUNTADMIN` in a Snowflake worksheet or via SnowSQL:

```sql
GRANT ROLE LIGHTHOUSE_ENGINEER TO USER <your_username>;
```

### Step 2.4: Set up resource monitors (optional but recommended)

```bash
snowsql -c lighthouse -f snowflake/monitoring/resource_monitors.sql
```

Sets credit quotas per warehouse with alerts at 75%, 90%, and auto-suspend at 100%.

---

## Phase 3: Load Seed Data

These scripts create raw tables and load synthetic CSV/JSON data from `data/` into Snowflake via PUT + COPY INTO.

**Important**: SnowSQL `PUT` commands use `file://` paths relative to where you run the command. Run from the repo root.

```bash
# From the repo root directory:
snowsql -c lighthouse -f snowflake/ingestion/load_oltp_seeds.sql -D env=DEV
snowsql -c lighthouse -f snowflake/ingestion/load_crm_seeds.sql -D env=DEV
snowsql -c lighthouse -f snowflake/ingestion/load_iot_seeds.sql -D env=DEV
snowsql -c lighthouse -f snowflake/ingestion/load_partner_feeds.sql -D env=DEV
snowsql -c lighthouse -f snowflake/ingestion/load_knowledge_base.sql -D env=DEV
```

This loads:
- `data/oltp/*.csv` → `RAW.OLTP.*` (11 CDC entities)
- `data/crm/*.csv` → `RAW.CRM.*` (8 SaaS objects)
- `data/iot_events/*.json` → `RAW.IOT.*` (as VARIANT)
- `data/partner_feeds/*` → `RAW.PARTNER_FEEDS.*` (with quarantine/error logging)
- `data/knowledge_base/*` → `RAW.KNOWLEDGE_BASE.*` (documents + text + chunks)

### Chunk the knowledge base documents

Split documents into ~512-token segments for search indexing:

```bash
snowsql -c lighthouse -f snowflake/ingestion/chunk_documents.sql -D env=DEV
```

### Verify data loaded

```sql
USE ROLE LIGHTHOUSE_ENGINEER;
USE WAREHOUSE TRANSFORM_WH;

SELECT 'customers' AS tbl, COUNT(*) AS cnt FROM LIGHTHOUSE_DEV_RAW.OLTP.customers
UNION ALL SELECT 'devices', COUNT(*) FROM LIGHTHOUSE_DEV_RAW.OLTP.devices
UNION ALL SELECT 'contracts', COUNT(*) FROM LIGHTHOUSE_DEV_RAW.OLTP.contracts
UNION ALL SELECT 'invoices', COUNT(*) FROM LIGHTHOUSE_DEV_RAW.OLTP.invoices;

SELECT 'accounts' AS tbl, COUNT(*) AS cnt FROM LIGHTHOUSE_DEV_RAW.CRM.accounts
UNION ALL SELECT 'cases', COUNT(*) FROM LIGHTHOUSE_DEV_RAW.CRM.cases;

SELECT COUNT(*) AS event_count FROM LIGHTHOUSE_DEV_RAW.IOT.telemetry_events;
SELECT COUNT(*) AS chunk_count FROM LIGHTHOUSE_DEV_RAW.KNOWLEDGE_BASE.document_chunks;
```

---

## Phase 4: Configure dbt

### Step 4.1: Create your profiles.yml

```bash
cp dbt/profiles.yml.example dbt/profiles.yml
```

Edit `dbt/profiles.yml` — hardcode credentials for local dev or use env vars:

```yaml
lighthouse:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "<your_account>"          # e.g. xy12345.us-east-1
      user: "<your_username>"
      password: "<your_password>"
      role: LIGHTHOUSE_ENGINEER
      warehouse: TRANSFORM_WH
      database: LIGHTHOUSE_DEV_ANALYTICS
      schema: MARTS
      threads: 4
```

Or set environment variables and keep the template syntax from `profiles.yml.example`:

```bash
export SNOWFLAKE_ACCOUNT=xy12345.us-east-1
export SNOWFLAKE_USER=your_username
export SNOWFLAKE_PASSWORD=your_password
```

### Step 4.2: Install dbt packages

```bash
cd dbt
dbt deps
```

Installs `dbt_utils`, `dbt_date`, and `elementary`.

### Step 4.3: Verify connection

```bash
dbt debug
```

You should see "All checks passed!"

---

## Phase 5: Run dbt

### Step 5.1: Load seeds, snapshots, and build

```bash
dbt seed        # Static reference data CSVs
dbt snapshot    # SCD Type 2 snapshots
dbt build       # Models (staging → intermediate → marts) + tests
```

`dbt build` runs models in dependency order and executes all associated tests. Expect a few minutes on a Small warehouse.

### Step 5.2: Verify

```bash
dbt test          # Run all tests standalone
dbt docs generate # Generate documentation
dbt docs serve    # Browse at http://localhost:8080
```

```sql
USE ROLE LIGHTHOUSE_ENGINEER;
USE DATABASE LIGHTHOUSE_DEV_ANALYTICS;

SELECT 'dim_customer' AS model, COUNT(*) AS cnt FROM MARTS.dim_customer
UNION ALL SELECT 'dim_device', COUNT(*) FROM MARTS.dim_device
UNION ALL SELECT 'fct_invoices', COUNT(*) FROM MARTS.fct_invoices
UNION ALL SELECT 'customer_360', COUNT(*) FROM MARTS.customer_360
UNION ALL SELECT 'knowledge_chunks', COUNT(*) FROM MARTS.knowledge_chunks;
```

---

## Phase 6: AI & Serving Features (optional)

These showcase the platform's AI-ready capabilities. Cortex Analyst, Cortex Search, Semantic Views, Dynamic Tables, and Streamlit in Snowflake all work on Standard Edition.

### Semantic view (Cortex Analyst)

```bash
snowsql -c lighthouse -f snowflake/semantic/contract_revenue_semantic.sql
```

Creates a semantic view over billing marts for natural-language querying.

### Cortex Search service

```bash
snowsql -c lighthouse -f snowflake/cortex/cortex_search_service.sql
```

Enables semantic search over chunked knowledge base documents.

### Dynamic Table (near-real-time serving)

```bash
snowsql -c lighthouse -f snowflake/serving/device_latest_status.sql
```

Creates a Dynamic Table with 5-minute target lag showing latest telemetry per device.

### Verify

```sql
SHOW DYNAMIC TABLES IN SCHEMA LIGHTHOUSE_DEV_SERVING.REALTIME;
SELECT * FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY());
```

---

## Phase 7: Governance (Enterprise Edition only — skip on Standard)

Object Tags, Dynamic Data Masking, and Row Access Policies all require Enterprise Edition or higher. If you're on Standard Edition, skip this phase entirely. The rest of the platform works without it — you just won't have column-level masking or row-level security.

If you upgrade to Enterprise later, run these scripts:

### Create governance objects

```bash
snowsql -c lighthouse -f snowflake/governance/tags.sql
snowsql -c lighthouse -f snowflake/governance/masking_policies.sql
snowsql -c lighthouse -f snowflake/governance/row_access_policies.sql
```

### Apply policies to mart tables

Run after dbt has built the marts:

```bash
snowsql -c lighthouse -f snowflake/governance/apply_policies.sql
```

Applies PII classification tags and dynamic masking to `customer_360` and `dim_customer`, marks financial columns as SENSITIVE.

### Verify masking

```sql
-- As LIGHTHOUSE_ENGINEER — see real data
USE ROLE LIGHTHOUSE_ENGINEER;
SELECT email, first_name FROM LIGHTHOUSE_DEV_ANALYTICS.MARTS.customer_360 LIMIT 5;

-- As LIGHTHOUSE_READER — see ***MASKED***
USE ROLE LIGHTHOUSE_READER;
SELECT email, first_name FROM LIGHTHOUSE_DEV_ANALYTICS.MARTS.customer_360 LIMIT 5;
```

---

## Phase 8: CI/CD Setup (GitHub Actions)

### Configure GitHub Secrets

In your repo: Settings → Secrets and variables → Actions:

| Secret | Value |
|--------|-------|
| `SNOWFLAKE_ACCOUNT` | Your Snowflake account identifier |
| `SNOWFLAKE_USER` | Service account username |
| `SNOWFLAKE_PASSWORD` | Service account password |

### Provision STAGING and PROD environments

```bash
snowsql -c lighthouse -f snowflake/infrastructure/deploy.sql -D env=STAGING
snowsql -c lighthouse -f snowflake/infrastructure/deploy.sql -D env=PROD
```

Load seed data into each environment the same way as Phase 3, substituting the env.

### How CI/CD works

- **Pull Request → CI** (`.github/workflows/ci.yml`): Runs `dbt build --select state:modified+` against STAGING
- **Merge to main → CD** (`.github/workflows/cd.yml`): Full `dbt build` against PROD, uploads manifest for future state comparisons

---

## Phase 9: Day-to-Day Operations

### Rebuilding after changes

```bash
cd dbt
dbt build --select state:modified+   # Only changed models + downstream
dbt build --select staging.crm+      # CRM staging and downstream
dbt build --select tag:billing        # All billing-tagged models
dbt test                              # All tests
dbt test --select tag:unit_test       # Unit tests only
dbt source freshness                  # Check source freshness
```

### Monitoring

```bash
snowsql -c lighthouse -f snowflake/monitoring/monitoring_queries.sql
```

Or run individual queries from that file for:
- Daily credit consumption by warehouse
- Longest-running queries
- Failed task executions
- Data product freshness

### Full refresh

```sql
DROP DATABASE IF EXISTS LIGHTHOUSE_DEV_RAW;
DROP DATABASE IF EXISTS LIGHTHOUSE_DEV_ANALYTICS;
DROP DATABASE IF EXISTS LIGHTHOUSE_DEV_SERVING;
```

Then re-run from Phase 2.

---

## Environment Quick Reference

| What | DEV | STAGING | PROD |
|------|-----|---------|------|
| Database prefix | `LIGHTHOUSE_DEV_*` | `LIGHTHOUSE_STAGING_*` | `LIGHTHOUSE_PROD_*` |
| Triggered by | Manual / branch | PR (CI) | Merge to main (CD) |
| dbt target | `dev` | `staging` | `prod` |

---

## Execution Order Summary

```bash
# ── 1. Infrastructure ──
snowsql -c lighthouse -f snowflake/infrastructure/deploy.sql -D env=DEV
# Grant yourself: GRANT ROLE LIGHTHOUSE_ENGINEER TO USER <you>;

# ── 2. Seed Data ──
snowsql -c lighthouse -f snowflake/ingestion/load_oltp_seeds.sql -D env=DEV
snowsql -c lighthouse -f snowflake/ingestion/load_crm_seeds.sql -D env=DEV
snowsql -c lighthouse -f snowflake/ingestion/load_iot_seeds.sql -D env=DEV
snowsql -c lighthouse -f snowflake/ingestion/load_partner_feeds.sql -D env=DEV
snowsql -c lighthouse -f snowflake/ingestion/load_knowledge_base.sql -D env=DEV
snowsql -c lighthouse -f snowflake/ingestion/chunk_documents.sql -D env=DEV

# ── 3. dbt ──
cp dbt/profiles.yml.example dbt/profiles.yml
# Edit profiles.yml with your credentials
cd dbt
dbt deps
dbt debug
dbt seed
dbt snapshot
dbt build

# ── 4. AI & Serving (optional) ──
cd ..
snowsql -c lighthouse -f snowflake/semantic/contract_revenue_semantic.sql
snowsql -c lighthouse -f snowflake/cortex/cortex_search_service.sql
snowsql -c lighthouse -f snowflake/serving/device_latest_status.sql

# ── 5. Governance (Enterprise Edition only — skip on Standard) ──
snowsql -c lighthouse -f snowflake/governance/tags.sql
snowsql -c lighthouse -f snowflake/governance/masking_policies.sql
snowsql -c lighthouse -f snowflake/governance/row_access_policies.sql
snowsql -c lighthouse -f snowflake/governance/apply_policies.sql

# ── 6. Resource Monitors (optional) ──
snowsql -c lighthouse -f snowflake/monitoring/resource_monitors.sql
```

---

## Troubleshooting

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| `PUT` fails with "file not found" | Running SnowSQL from wrong directory | Run from repo root so `file://data/...` paths resolve |
| `dbt debug` fails connection | Wrong account identifier format | Use `<account>.<region>` format, e.g. `xy12345.us-east-1` |
| `COPY INTO` loads 0 rows | Stage is empty (PUT didn't run) | Re-run the PUT commands, check `LIST @stage_name` |
| `dbt build` fails on staging models | Raw tables don't exist or are empty | Re-run Phase 3 seed loading |
| Governance `ALTER TABLE` fails | Mart tables don't exist yet | Run `dbt build` first, then apply governance |
| CI pipeline fails | Missing GitHub secrets | Add `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD` |
| `deploy.sql` `!source` not recognized | Not using SnowSQL CLI | Run individual scripts 01–08 separately |
| Cortex features unavailable | Region doesn't support Cortex yet | Check [Cortex availability by region](https://docs.snowflake.com/en/user-guide/snowflake-cortex/llm-functions#availability) |
| Governance scripts fail | Standard Edition doesn't support tags/masking/RAP | Upgrade to Enterprise, or skip Phase 7 |
| Dynamic Tables not refreshing | Upstream data missing or lag config | Check `SHOW DYNAMIC TABLES` and verify target lag |