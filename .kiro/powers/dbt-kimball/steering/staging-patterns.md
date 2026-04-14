# dbt Staging Layer Patterns

## Model Template

```sql
-- stg_{source}__{entity}.sql
WITH source AS (
    SELECT * FROM {{ source('{source_name}', '{table_name}') }}
),
deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY {natural_key}
            ORDER BY _source_ts DESC
        ) AS _row_num
    FROM source
    WHERE _op != 'DELETE'
),
renamed AS (
    SELECT
        -- Keys first
        {natural_key},
        -- Attributes (renamed to snake_case, cast to standard types)
        LOWER({email_col}) AS email,
        CAST({date_col} AS DATE) AS {date_col},
        -- Metadata last
        _source_ts,
        _loaded_at,
        _connector_batch_id
    FROM deduplicated
    WHERE _row_num = 1
)
SELECT * FROM renamed
```

## Materialization Rules

| Source Volume | Materialization | Incremental Strategy |
|--------------|----------------|---------------------|
| High (IoT, CDC) | `incremental` | `_loaded_at` filter |
| Low (reference) | `view` | N/A |

## Rules

- MUST NOT apply business logic or cross-source joins
- MUST rename all columns to snake_case
- MUST cast to platform-standard types
- MUST order columns: keys → attributes → metadata
- MUST deduplicate CDC sources to latest record per natural key
- MUST define source freshness checks
- MUST apply not_null on PKs and unique on natural keys
