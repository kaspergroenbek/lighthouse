# Tech Stack

## Core Technologies

- **Snowflake** (Enterprise Edition) — Cloud data warehouse, ingestion layer, governance, AI features
- **dbt Core 1.8+** (or dbt Cloud) — ELT transformation framework, semantic layer, testing, documentation
- **SQL** — Primary language for Snowflake infrastructure scripts and dbt models (Jinja-templated SQL)
- **Python** — Streamlit app, CI/CD scripts
- **YAML** — dbt configuration, semantic layer definitions, CI/CD pipelines

## Snowflake Features Used

- Dynamic Tables (near-real-time serving, target lag configuration)
- Streams and Tasks (event-driven pipelines, scheduled operations)
- Cortex Analyst (natural-language querying via semantic views)
- Cortex Search (semantic search over unstructured content)
- Semantic Views (`CREATE SEMANTIC VIEW` SQL syntax)
- Object Tags, Dynamic Data Masking, Row Access Policies
- Resource Monitors (cost control)
- Internal Stages + COPY INTO (simulated ingestion)
- VARIANT columns (semi-structured IoT JSON data)
- Streamlit in Snowflake

## dbt Packages

- `dbt_utils` — surrogate key generation, generic tests, utilities
- `dbt_date` — date dimension generation
- `elementary` — data observability, test result storage

## dbt Features Used

- Model contracts (enforced column names, types, constraints)
- Model versions (non-breaking schema evolution, starting at v1)
- Model access (`public`, `protected`, `private`)
- Model groups (domain-aligned: customer, billing, device, service)
- Unit tests (intermediate layer business logic validation)
- Snapshots (SCD Type 2 via timestamp strategy)
- MetricFlow semantic layer (inline on model YAML, dbt v1.12+ syntax)
- Source freshness checks
- Exposures (downstream consumer documentation)
- `state:modified+` selection (CI optimization)

## CI/CD

- **GitHub Actions** — CI on pull request, CD on merge to main
- CI runs `dbt build --select state:modified+` against a CI-specific Snowflake database
- CD runs full `dbt build` against PROD

## Common Commands

```bash
# dbt
dbt deps                              # Install packages
dbt compile                           # Compile models (validation)
dbt build                             # Run models + tests
dbt build --select staging+           # Build staging and downstream
dbt build --select state:modified+    # Build only modified models (CI)
dbt test                              # Run all tests
dbt test --select tag:unit_test       # Run unit tests only
dbt snapshot                          # Run SCD2 snapshots
dbt seed                              # Load seed CSV data
dbt docs generate                     # Generate documentation site
dbt docs serve                        # Serve docs locally
dbt source freshness                  # Check source freshness

# Snowflake infrastructure deployment
snowsql -f snowflake/infrastructure/deploy.sql -D env=PROD

# Seed data loading (PUT to internal stages)
snowsql -f snowflake/ingestion/load_seeds.sql
```

## Environment Strategy

| Environment | Database Prefix         | Purpose                          |
|-------------|------------------------|----------------------------------|
| DEV         | `LIGHTHOUSE_DEV_*`     | Developer iteration, branches    |
| STAGING     | `LIGHTHOUSE_STAGING_*` | CI validation, PR builds         |
| PROD        | `LIGHTHOUSE_PROD_*`    | Production serving               |
