---
name: "dbt-kimball"
displayName: "dbt Kimball Data Engineering"
description: "dbt patterns for Kimball dimensional modeling, model contracts, semantic layer, snapshots, testing, and data product governance"
keywords: ["dbt", "kimball", "dimensional", "star schema", "surrogate key", "scd", "snapshot", "model contract", "semantic layer", "metricflow", "staging", "intermediate", "marts", "incremental", "unit test"]
---

# dbt Kimball Data Engineering Power

This power provides dbt-specific patterns for building Kimball-style dimensional models with modern dbt features (v1.12+).

## When to Load Steering Files

- Writing staging models (stg_*) → `staging-patterns.md`
- Writing intermediate models (int_*) → `intermediate-patterns.md`
- Writing marts models (dim_*, fct_*, bridge_*) → `marts-and-kimball.md`
- Writing snapshots (snp_*) → `snapshot-patterns.md`
- Writing tests or YAML schema files → `testing-patterns.md`
- Configuring semantic layer or metrics → `semantic-layer.md`

## Core Rules

- Staging models MUST NOT contain business logic — only rename, cast, deduplicate
- Intermediate models MUST be `protected` access
- Marts models MUST be `public` access with enforced model contracts
- All surrogate keys MUST use `dbt_utils.generate_surrogate_key()`
- All mart models MUST have column descriptions and grain documentation
- Naming: `stg_{source}__{entity}`, `int_{domain}__{desc}`, `dim_{entity}`, `fct_{process}`
