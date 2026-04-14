# dbt Marts & Kimball Dimensional Modeling Patterns

## Surrogate Key Generation

```sql
{{ dbt_utils.generate_surrogate_key(['natural_key_col1', 'natural_key_col2']) }} AS {entity}_sk
```

## Dimension Template (SCD Type 1)

```sql
WITH source AS (
    SELECT * FROM {{ ref('int_{domain}__{entity}') }}
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['{natural_key}']) }} AS {entity}_sk,
    {natural_key},
    {attribute_columns},
    CURRENT_TIMESTAMP() AS _loaded_at
FROM source
```

## Dimension Template (SCD Type 2 — from snapshot)

```sql
WITH snapshot AS (
    SELECT * FROM {{ ref('snp_{entity}') }}
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['{natural_key}', 'dbt_valid_from']) }} AS {entity}_sk,
    {natural_key},
    {attribute_columns},
    dbt_valid_from AS valid_from,
    dbt_valid_to AS valid_to,
    CASE WHEN dbt_valid_to IS NULL THEN TRUE ELSE FALSE END AS is_current
FROM snapshot
```

## Transaction Fact — join dims via surrogate keys

## Periodic Snapshot Fact — grain: one row per entity per time period, aggregate measures

## Accumulating Snapshot Fact — grain: one row per entity, milestone timestamps + duration measures

## Bridge Table — grain: one row per assignment period, effective_from/effective_to

## YAML Contract Template (MUST be on every mart model)

```yaml
models:
  - name: dim_{entity}
    description: "{Entity} dimension — grain: one row per {entity}"
    config:
      contract:
        enforced: true
      access: public
      group: {domain}
    latest_version: 1
    columns:
      - name: {entity}_sk
        data_type: varchar
        constraints:
          - type: not_null
        tests:
          - unique
          - not_null
    versions:
      - v: 1
```

## Rules

- Every mart model MUST have enforced model contract, public access, group, version v1
- Surrogate keys MUST use `dbt_utils.generate_surrogate_key()`
- SCD2 dims MUST filter `is_current = TRUE` when joining to facts
- Grain MUST be documented in model description
