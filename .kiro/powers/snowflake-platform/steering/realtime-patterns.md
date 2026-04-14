# Snowflake Real-Time Patterns

## Dynamic Tables

Use Dynamic Tables for near-real-time serving where dbt batch scheduling is insufficient.

```sql
CREATE OR REPLACE DYNAMIC TABLE {schema}.{name}
  TARGET_LAG = '{num} {seconds|minutes|hours|days}'
  WAREHOUSE = {warehouse}
  REFRESH_MODE = AUTO
AS
  {query};
```

### When to Use Dynamic Tables vs dbt Incrementals

| Criteria | Dynamic Table | dbt Incremental |
|----------|--------------|-----------------|
| Freshness need | < 15 minutes | >= 15 minutes |
| Scheduling | Snowflake-managed (declarative) | dbt orchestrator (imperative) |
| Transformation complexity | Simple SQL | Complex Jinja/SQL |
| Testing | No dbt tests | Full dbt test suite |
| Lineage | Snowflake lineage only | dbt lineage + docs |

### Rules

- Dynamic Tables MUST be in the SERVING schema, NOT in MARTS
- Dynamic Tables MUST NOT duplicate dbt mart logic
- Dynamic Tables SHOULD read from RAW or STAGING layers
- TARGET_LAG MUST be explicitly justified in documentation
- WAREHOUSE MUST be SERVING_WH (not TRANSFORM_WH)

## Streams and Tasks

Use Streams + Tasks for event-driven micro-pipelines where neither dbt nor Dynamic Tables fit.

```sql
CREATE OR REPLACE STREAM {stream_name}
  ON TABLE {source_table}
  SHOW_INITIAL_ROWS = FALSE;

CREATE OR REPLACE TASK {task_name}
  WAREHOUSE = {warehouse}
  SCHEDULE = '{cron_or_interval}'
  WHEN SYSTEM$STREAM_HAS_DATA('{stream_name}')
AS
  {sql_statement};

ALTER TASK {task_name} RESUME;
```

### Rules

- Streams/Tasks SHOULD be used sparingly — prefer Dynamic Tables for most near-real-time cases
- Tasks MUST have a WHEN clause to avoid unnecessary execution
- Tasks MUST be explicitly resumed after creation (`ALTER TASK ... RESUME`)
