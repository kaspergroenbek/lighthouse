---
name: "lighthouse"
displayName: "Lighthouse Data Platform"
description: "Conventions, architecture rules, and workflows for the NordHjem Energy Lighthouse data platform built on Snowflake and dbt"
keywords: ["lighthouse", "nordhjem", "dbt", "snowflake", "data warehouse", "elt", "staging", "marts", "intermediate", "kimball", "cortex", "semantic layer", "metricflow", "dynamic tables"]
---

# Lighthouse Data Platform Power

You are working on **Lighthouse**, an AI-ready data product platform for NordHjem Energy, built on Snowflake (Enterprise Edition) and dbt Core 1.8+.

## Core Principles

- Snowflake owns ingestion and infrastructure; dbt owns ALL transformation logic.
- Three-layer ELT: staging → intermediate → marts (Kimball star schema).
- All Snowflake infrastructure SQL MUST be idempotent (`CREATE OR REPLACE` / `CREATE IF NOT EXISTS`).
- Surrogate keys MUST use `dbt_utils.generate_surrogate_key()`.
- Domain groups: `customer`, `billing`, `device`, `service`.

## When to Load Steering Files

- Writing or modifying dbt models (staging, intermediate, or marts) → `dbt-models.md`
- Writing or modifying Snowflake SQL scripts (infrastructure, ingestion, governance) → `snowflake-sql.md`
- Working with CI/CD, testing, or deployment → `testing-and-cicd.md`
