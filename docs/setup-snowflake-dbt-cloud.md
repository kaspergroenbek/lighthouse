# Snowflake + dbt Cloud Setup Guide

This guide is the primary operating model for Version 1 of Lighthouse:

- Snowflake hosts infrastructure, raw data, governance, semantic objects, Cortex Search, Dynamic Tables, and Streamlit
- dbt Cloud runs the dbt project in `dbt/`
- GitHub remains the source of truth

## 1. Target Model

Use this responsibility split:

- Snowsight:
  - run `snowflake/infrastructure/deploy.sql`
  - run `snowflake/ingestion_web/*.sql`
  - run post-dbt SQL in `snowflake/semantic`, `snowflake/cortex`, `snowflake/governance`, `snowflake/serving`, and `snowflake/monitoring`
  - create the Streamlit app
- dbt Cloud:
  - connect the GitHub repo
  - install packages
  - run `dbt seed`
  - run `dbt snapshot`
  - run `dbt build`

## 2. Environment Convention

All environment-specific Snowflake-native scripts now follow a simple pattern:

- set `LIGHTHOUSE_ENV` at the top of the SQL file
- derive database names from that value

Recommended values:

- `DEV`
- `STAGING`
- `PROD`

For the first full hosted setup, start with `PROD` to match the primary demo surface.

## 3. Prerequisites

Before starting, make sure you have:

- a Snowflake account with permission to create warehouses, databases, roles, and users
- a dbt Cloud account
- the repo pushed to GitHub
- access to connect dbt Cloud to that GitHub repository

## 4. Snowflake Setup

### Step 1: Create core platform objects

In Snowsight:

1. Open a SQL worksheet.
2. Open `snowflake/infrastructure/deploy.sql`.
3. Change:

```sql
env VARCHAR DEFAULT 'DEV';
```

to:

```sql
env VARCHAR DEFAULT 'PROD';
```

4. Run the script.

This creates:

- `LIGHTHOUSE_PROD_RAW`
- `LIGHTHOUSE_PROD_ANALYTICS`
- `LIGHTHOUSE_PROD_SERVING`
- warehouses
- roles
- schemas
- stages
- file formats

### Step 2: Create a dbt Cloud user

Create a dedicated dbt Cloud user in Snowflake.

Recommended:

- user: `DBT_CLOUD_LIGHTHOUSE`
- warehouse: `TRANSFORM_WH`
- default role: `LIGHTHOUSE_TRANSFORMER`

For deployment credentials, prefer key pair auth.

At minimum, the dbt Cloud role needs:

- usage on `TRANSFORM_WH`
- usage on `LIGHTHOUSE_PROD_ANALYTICS`
- create/select/insert/update/delete where dbt needs to build objects
- usage/select on `LIGHTHOUSE_PROD_RAW`

If you want the fastest safe start, you can temporarily grant the service user `LIGHTHOUSE_ENGINEER` and tighten later.

### Step 3: Load raw data with the orchestrator

Use the orchestration entrypoint instead of running each loader manually.

Recommended worksheet command:

```sql
EXECUTE IMMEDIATE FROM @<repo_clone>/branches/<branch>/snowflake/orchestration/load_raw.sql
USING (
  env => 'PROD',
  repo_root => '@<repo_clone>/branches/<branch>'
);
```

This orchestrator executes:

- `snowflake/ingestion_web/load_oltp_seeds.sql`
- `snowflake/ingestion_web/load_crm_seeds.sql`
- `snowflake/ingestion_web/load_iot_seeds.sql`
- `snowflake/ingestion_web/load_partner_feeds.sql`
- `snowflake/ingestion_web/load_knowledge_base.sql`
- `snowflake/ingestion_web/chunk_documents.sql`

Preferred entrypoint:

- `snowflake/orchestration/bootstrap_orchestrator.sql`

### Step 4: Sanity-check raw data

Run a few checks in Snowsight:

```sql
SELECT COUNT(*) FROM LIGHTHOUSE_PROD_RAW.OLTP.customers;
SELECT COUNT(*) FROM LIGHTHOUSE_PROD_RAW.CRM.accounts;
SELECT COUNT(*) FROM LIGHTHOUSE_PROD_RAW.IOT.telemetry_events;
SELECT COUNT(*) FROM LIGHTHOUSE_PROD_RAW.KNOWLEDGE_BASE.document_chunks;
```

## 5. dbt Cloud Setup

### Step 1: Connect GitHub

In dbt Cloud:

1. Create a new project.
2. Choose your Git provider.
3. Connect the Lighthouse repository.
4. Set the project subdirectory to:

```text
dbt
```

### Step 2: Configure the warehouse connection

Create a Snowflake connection using:

- account: your Snowflake account identifier
- user: `DBT_CLOUD_LIGHTHOUSE`
- warehouse: `TRANSFORM_WH`
- role: `LIGHTHOUSE_TRANSFORMER` or `LIGHTHOUSE_ENGINEER`
- database: `LIGHTHOUSE_PROD_ANALYTICS`
- schema: `MARTS`

Use:

- password auth for quick initial development if needed
- key pair auth for deployment environments

### Step 3: Create environments

Create two environments:

1. Development
2. Production

Recommended initial values for both:

- database: `LIGHTHOUSE_PROD_ANALYTICS`
- warehouse: `TRANSFORM_WH`
- role: `LIGHTHOUSE_ENGINEER` for dev, `LIGHTHOUSE_TRANSFORMER` for prod if available

### Step 4: Add dbt Cloud environment variables

Set these in dbt Cloud:

- `LIGHTHOUSE_ENV=PROD`
- `LIGHTHOUSE_RAW_DB=LIGHTHOUSE_PROD_RAW`

You can add others later, but these are the important ones for this repo.

## 6. First dbt Cloud Run

Create a production job with these commands:

```bash
dbt deps
dbt seed
dbt snapshot
dbt build
```

Then run the job manually once.

Expected outcome:

- seeds loaded into `SEEDS`
- snapshots built in `SNAPSHOTS`
- models built in `STAGING`, `INTERMEDIATE`, and `MARTS`
- tests executed

If the run fails, check:

- raw data exists in `LIGHTHOUSE_PROD_RAW`
- `LIGHTHOUSE_RAW_DB` is set correctly in dbt Cloud
- the dbt Cloud role can read raw and write analytics

## 7. Post-dbt Snowflake Setup

After the dbt run succeeds, go back to Snowsight and run:

```sql
EXECUTE IMMEDIATE FROM @<repo_clone>/branches/<branch>/snowflake/orchestration/post_dbt.sql
USING (
  env => 'PROD',
  repo_root => '@<repo_clone>/branches/<branch>'
);
```

This orchestrator executes the semantic, cortex, governance, serving, and monitoring SQL in the correct order.

## 8. Streamlit Setup

In Snowsight:

1. Go to `Projects` -> `Streamlit`.
2. Create a new app in `LIGHTHOUSE_PROD_SERVING`.
3. Use warehouse `SERVING_WH`.
4. Paste in `streamlit/app.py`.
5. Save and run the app.

The app now derives the analytics database from the current serving database, so:

- `LIGHTHOUSE_PROD_SERVING` maps to `LIGHTHOUSE_PROD_ANALYTICS`
- `LIGHTHOUSE_DEV_SERVING` maps to `LIGHTHOUSE_DEV_ANALYTICS`

## 9. Daily Operating Model

Use this workflow day to day:

- edit dbt models in GitHub and dbt Cloud IDE
- run dbt in dbt Cloud
- manage Snowflake-native assets in Snowsight
- refresh the Git-backed Snowflake workspace before executing orchestration files
- use GitHub as source of truth for both

## 10. Updating the Repo in Snowflake

When the repo changes in GitHub:

1. Open your Snowsight workspace connected to the repo.
2. Fetch or pull the latest changes from the remote branch.
3. Confirm the updated files are visible in the workspace.
4. Run the orchestration entrypoints from the refreshed repo state.

Use these entry files as your main Snowflake runtime entrypoints:

- `snowflake/orchestration/load_raw.sql`
- `snowflake/orchestration/post_dbt.sql`

## 11. Suggested Next Improvement

After the first hosted setup is working:

1. create a true `DEV` environment in Snowflake and dbt Cloud
2. mirror the same setup with `LIGHTHOUSE_ENV=DEV`
3. update docs and demos to treat `PROD` as published demo and `DEV` as build sandbox
