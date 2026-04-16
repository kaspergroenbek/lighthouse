# Snowflake + dbt Cloud Setup Guide

This guide is the primary operating model for Version 1 of Lighthouse.

## Responsibility Split

- Snowflake and Snowsight:
  - infrastructure deployment
  - raw data loading
  - semantic objects
  - serving objects
  - Streamlit app hosting
- dbt Cloud:
  - package installation
  - seeds
  - models
  - snapshots
  - tests
  - docs and catalog artifacts
- GitHub:
  - source of truth for the repo

## Environment Convention

The hosted setup currently assumes `PROD` as the primary deployed environment.

Use these values in dbt Cloud:
- `DBT_LIGHTHOUSE_ENV=PROD`
- `DBT_LIGHTHOUSE_RAW_DB=LIGHTHOUSE_PROD_RAW`

## Snowflake Setup

### 1. Deploy infrastructure

Run `snowflake/infrastructure/deploy.sql` in Snowsight with:

```sql
env VARCHAR DEFAULT 'PROD';
```

### 2. Create the Snowflake Git repository clone

Use a Snowflake `GIT REPOSITORY` object so orchestration files can be executed with `EXECUTE IMMEDIATE FROM`.

### 3. Run bootstrap orchestrator

Recommended entrypoint:

```sql
EXECUTE IMMEDIATE FROM @<repo_clone>/branches/<branch>/snowflake/orchestration/bootstrap_orchestrator.sql
USING (
  env => 'PROD',
  repo_root => '@<repo_clone>/branches/<branch>'
);
```

This bootstrap flow loads:
- OLTP raw data
- CRM raw data
- IoT raw data
- partner feeds

### 4. Validate raw layer

Run checks such as:

```sql
SELECT COUNT(*) FROM LIGHTHOUSE_PROD_RAW.OLTP.customers;
SELECT COUNT(*) FROM LIGHTHOUSE_PROD_RAW.CRM.accounts;
SELECT COUNT(*) FROM LIGHTHOUSE_PROD_RAW.IOT.telemetry_events;
```

## dbt Cloud Setup

### 1. Create the project

- connect the GitHub repo
- set project subdirectory to `dbt`

### 2. Configure the Snowflake connection

Recommended values:
- warehouse: `TRANSFORM_WH`
- database: `LIGHTHOUSE_PROD_ANALYTICS`
- schema: `MARTS`
- role: `LIGHTHOUSE_TRANSFORMER` or `LIGHTHOUSE_ENGINEER`

### 3. Configure environments

Use the existing Development environment plus a Production deployment environment.

For the initial hosted setup, both can point at `LIGHTHOUSE_PROD_ANALYTICS`, but the deployment environment should be the one used for the production build job.

### 4. Set environment variables

Use dbt Cloud-compatible names:
- `DBT_LIGHTHOUSE_ENV`
- `DBT_LIGHTHOUSE_RAW_DB`

Recommended values:
- Development: `PROD`, `LIGHTHOUSE_PROD_RAW`
- Production: `PROD`, `LIGHTHOUSE_PROD_RAW`

## Recommended dbt Cloud Jobs

### Production Build

```bash
dbt deps
dbt seed
dbt build
```

### Production Build + Docs

```bash
dbt deps
dbt seed
dbt build
dbt docs generate
```

Use the docs job to populate the dbt Cloud catalog and documentation site.

## Important Run-Order Note

Do not use `dbt snapshot` as a standalone step before `dbt build` in this project.

The snapshots depend on staging models, so the safe hosted run order is:

```bash
dbt deps
dbt seed
dbt build
```

and optionally:

```bash
dbt docs generate
```

## Post-dbt Snowflake Setup

After the dbt production run succeeds, run:

```sql
EXECUTE IMMEDIATE FROM @<repo_clone>/branches/<branch>/snowflake/orchestration/post_dbt_orchestrator.sql
USING (
  env => 'PROD',
  repo_root => '@<repo_clone>/branches/<branch>'
);
```

This creates:
- semantic assets
- serving objects

## Streamlit Setup

In Snowsight:
1. create a Streamlit app in `LIGHTHOUSE_PROD_SERVING`
2. use warehouse `SERVING_WH`
3. load `streamlit/app.py`
4. run the app

## What Belongs Where

Snowflake side:
- `snowflake/infrastructure/`
- `snowflake/ingestion_web/`
- `snowflake/orchestration/`
- `snowflake/semantic/`
- `snowflake/serving/`
- `streamlit/`

 dbt Cloud side:
- `dbt/models/`
- `dbt/snapshots/`
- `dbt/seeds/`
- `dbt/tests/`
- `dbt/macros/`

## Catalog Expectations

In dbt Cloud, the catalog will show:
- Lighthouse business models
- internal package models such as Elementary observability artifacts

It is normal for internal package models to show weaker health metadata than curated business marts.

## Recommended Follow-up

After the first hosted setup is stable:
1. create a true `DEV` Snowflake environment
2. split Development and Production in dbt Cloud cleanly
3. continue improving metadata and docs for curated marts only
