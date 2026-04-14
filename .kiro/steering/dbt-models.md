---
inclusion: fileMatch
fileMatchPattern: "dbt/models/**/*.sql"
---

# dbt Model Conventions

When writing dbt SQL models:

- Staging (`stg_`): rename, cast, deduplicate ONLY — no business logic, no cross-source joins
- Intermediate (`int_`): business logic, entity matching, derived fields — `protected` access
- Marts (`dim_`, `fct_`, `bridge_`): Kimball star schema — `public` access, enforced contracts, versioned

## SQL Style

- Use CTEs (WITH blocks), not subqueries
- CTE naming: `source`, `renamed`, `deduplicated`, `joined`, `final`
- Column order: keys → attributes → measures → metadata
- All columns snake_case
- Surrogate keys via `{{ dbt_utils.generate_surrogate_key([...]) }}`
- SCD2 dimensions reference snapshots (`ref('snp_*')`), not staging models

## Materialization

- Staging high-volume: `incremental` with `_loaded_at`
- Staging low-volume: `view`
- Intermediate lightweight: `ephemeral` or `view`
- Intermediate heavy: `table`
- Marts: `table` (default)

## Every mart model YAML MUST have

- `contract: enforced: true`
- `access: public`
- `group: {domain}`
- `latest_version: 1`
- Column descriptions and grain documentation
