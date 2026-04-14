---
inclusion: fileMatch
fileMatchPattern: "snowflake/**/*.sql"
---

# Snowflake SQL Conventions

When writing Snowflake SQL scripts:

- All DDL MUST use `CREATE OR REPLACE` or `CREATE ... IF NOT EXISTS`
- All scripts MUST be idempotent — re-execution produces no errors
- Use the correct warehouse per workload: INGESTION_WH (loading), TRANSFORM_WH (dbt), SERVING_WH (queries), AI_WH (Cortex)
- Use the correct role hierarchy: LIGHTHOUSE_ADMIN → ENGINEER → TRANSFORMER → READER
- Database naming: `LIGHTHOUSE_{ENV}_{LAYER}` (RAW, ANALYTICS, SERVING)
- Include comments on all objects explaining their purpose
- Governance objects (tags, masking, row access) go in `snowflake/governance/`
- Infrastructure objects go in `snowflake/infrastructure/` with numbered prefixes (01-08)
- Semantic views go in `snowflake/semantic/` using `CREATE SEMANTIC VIEW` syntax
