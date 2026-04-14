# dbt Snapshot Patterns (SCD Type 2)

## YAML Configuration (dbt v1.9+)

```yaml
snapshots:
  - name: snp_{entity}
    relation: ref('stg_{source}__{entity}')
    config:
      schema: snapshots
      unique_key: {natural_key}
      strategy: timestamp
      updated_at: updated_at
```

## Metadata Columns (auto-generated)

- `dbt_valid_from` — Start of validity period
- `dbt_valid_to` — End of validity (NULL = current)
- `dbt_scd_id` — Unique snapshot record ID
- `dbt_updated_at` — Snapshot run timestamp

## Rules

- MUST use `timestamp` strategy with `updated_at` column
- MUST target the SNAPSHOTS schema
- MUST define `unique_key` as the natural key
- Downstream SCD2 dims MUST reference the snapshot, not staging
- DAG order: staging → snapshots → intermediate → marts
