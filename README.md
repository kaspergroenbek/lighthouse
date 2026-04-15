# Lighthouse - AI-Ready Data Product Platform

Lighthouse is a portfolio-grade data platform for NordHjem Energy, a fictional Nordic connected-home and energy services company.

Version 1 of the project is designed to run with:
- Snowflake for infrastructure, ingestion, governance, serving, and app hosting
- dbt Cloud for transformation, testing, and documentation
- GitHub as the source of truth

## Primary Operating Model

The primary workflow is:
1. GitHub stores the codebase
2. Snowflake hosts raw, analytics, serving, semantic, governance, and Streamlit assets
3. dbt Cloud runs the dbt project in `dbt/`

The recommended setup path is documented in:
- `docs/setup-snowflake-dbt-cloud.md`

The warehouse design in Kimball terms is documented in:
- `docs/kimball-architecture.md`

## Architecture

```mermaid
graph TB
    subgraph Sources
        OLTP[PostgreSQL CDC]
        CRM[SaaS CRM]
        IOT[IoT Telemetry]
        PARTNER[Partner Feeds]
        KB[Knowledge Base]
    end
    subgraph "Snowflake + dbt Cloud"
        RAW[RAW Layer]
        STG[Staging]
        INT[Intermediate]
        MARTS[Marts - Kimball Star Schema]
        SEM[Semantic and Serving]
    end
    subgraph Consumption
        CORTEX_A[Cortex Analyst]
        CORTEX_S[Cortex Search]
        DT[Dynamic Tables]
        APP[Streamlit App]
        DOCS[dbt Docs Catalog]
    end
    Sources --> RAW --> STG --> INT --> MARTS --> SEM
    MARTS --> CORTEX_A & CORTEX_S & DT & APP & DOCS
```

## Key Capabilities

- 5 ingestion patterns: CDC, SaaS, batch, streaming, unstructured
- 3-layer dbt ELT: staging -> intermediate -> marts
- Kimball dimensional marts with conformed dimensions, facts, and bridges
- Customer 360, billing, device, service, and knowledge data products
- Snowflake-native semantic, governance, serving, and app layers
- dbt tests, contracts, snapshots, unit tests, and docs catalog

## Quick Start

For the hosted setup, use this flow:

1. Run Snowflake infrastructure deployment in Snowsight
2. Run the raw-load orchestrator in Snowflake
3. Configure dbt Cloud against the `dbt/` subdirectory
4. Run:

```bash
dbt deps
dbt seed
dbt build
dbt docs generate
```

5. Run the Snowflake post-dbt orchestrator
6. Create the Streamlit app in Snowflake

Do not use the old CLI-first run order as the default hosted path.

## Repository Structure

```text
lighthouse/
|-- dbt/                    # dbt transformation project
|   |-- models/
|   |   |-- staging/        # source-conforming cleanup and deduplication
|   |   |-- intermediate/   # integration and harmonization logic
|   |   `-- marts/          # Kimball dimensions, facts, bridges, data products
|   |-- snapshots/          # SCD Type 2 snapshots
|   |-- seeds/              # static reference data
|   |-- macros/             # custom macros and generic tests
|   `-- tests/              # generic and unit tests
|-- snowflake/
|   |-- infrastructure/     # idempotent setup scripts
|   |-- ingestion/          # local CLI-oriented loaders
|   |-- ingestion_web/      # Snowsight-friendly loaders
|   |-- orchestration/      # bootstrap and post-dbt entrypoints
|   |-- governance/         # tags, masking, row access policies
|   |-- semantic/           # semantic objects
|   |-- cortex/             # Cortex Search service
|   |-- serving/            # Dynamic Tables and serving SQL
|   `-- monitoring/         # cost and monitoring SQL
|-- streamlit/              # Streamlit in Snowflake app
|-- data/                   # synthetic source data
|-- docs/                   # setup, architecture, ADRs, modeling docs
`-- .github/workflows/      # CI/CD pipelines
```

## Important Notes

- `snowflake/ingestion/` remains useful as a local fallback path, but it is not the primary hosted workflow.
- `snowflake/orchestration/bootstrap_orchestrator.sql` is the preferred Snowflake-side bootstrap entrypoint.
- `snowflake/orchestration/post_dbt_orchestrator.sql` is the preferred Snowflake-side post-dbt entrypoint.
- The service area now follows a Kimball pattern with a ticket-grain fact and a ticket-to-customer bridge.

## Documentation

- `docs/setup-snowflake-dbt-cloud.md`
- `docs/kimball-architecture.md`
- `docs/ingestion-architecture.md`
- `docs/semantic-layer-mapping.md`
- `docs/governance-mapping.md`
- `docs/data-product-catalog.md`
- `docs/adr/`
