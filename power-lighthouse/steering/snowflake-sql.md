# Snowflake SQL Conventions

## Database Layout

| Database                     | Schema           | Contents                          |
|------------------------------|------------------|-----------------------------------|
| `LIGHTHOUSE_{ENV}_RAW`       | `OLTP`           | CDC raw tables                    |
|                              | `CRM`            | SaaS connector raw tables         |
|                              | `IOT`            | Streaming telemetry raw tables    |
|                              | `PARTNER_FEEDS`  | Batch file raw tables             |
|                              | `KNOWLEDGE_BASE` | Document tracking, text, chunks   |
| `LIGHTHOUSE_{ENV}_ANALYTICS` | `STAGING`        | dbt staging models                |
|                              | `INTERMEDIATE`   | dbt intermediate models           |
|                              | `MARTS`          | Dimensional model (dims + facts)  |
|                              | `SNAPSHOTS`      | dbt SCD2 snapshots                |
|                              | `SEMANTIC`       | Semantic views for Cortex Analyst |
|                              | `TEST_RESULTS`   | dbt test result history           |
| `LIGHTHOUSE_{ENV}_SERVING`   | `REALTIME`       | Dynamic Tables (near-real-time)   |

`{ENV}` is one of: `DEV`, `STAGING`, `PROD`.

## Script Rules

- All infrastructure SQL MUST be idempotent: use `CREATE OR REPLACE` or `CREATE ... IF NOT EXISTS`.
- Infrastructure scripts live in `snowflake/infrastructure/` and are numbered `01-08` plus a `deploy.sql` orchestrator.
- Ingestion scripts live in `snowflake/ingestion/` and use `COPY INTO` from internal stages.
- Governance scripts (tags, masking, row access policies) live in `snowflake/governance/`.
- Semantic view definitions (`CREATE SEMANTIC VIEW`) live in `snowflake/semantic/`.
- Monitoring queries live in `snowflake/monitoring/`.

## Snowflake Features

- **Dynamic Tables**: Use for near-real-time serving layer with target lag configuration.
- **Streams and Tasks**: Use for event-driven pipelines and scheduled operations.
- **Cortex Analyst**: Pair with semantic views in the `SEMANTIC` schema.
- **Cortex Search**: Use for semantic search over chunked knowledge base documents.
- **VARIANT columns**: Use for semi-structured IoT JSON telemetry data.
- **Object Tags + Dynamic Data Masking + Row Access Policies**: Apply for governance.
- **Resource Monitors**: Configure for cost control.

## Deployment

```bash
# Deploy infrastructure to an environment
snowsql -f snowflake/infrastructure/deploy.sql -D env=PROD

# Load seed data to internal stages
snowsql -f snowflake/ingestion/load_seeds.sql
```
