---
name: "snowflake-platform"
displayName: "Snowflake Platform Engineering"
description: "Snowflake DDL patterns for data platform engineering: semantic views, dynamic tables, Cortex AI, governance policies, stages, and infrastructure scripts"
keywords: ["snowflake", "dynamic table", "semantic view", "cortex", "masking", "row access", "stage", "copy into", "warehouse", "resource monitor", "tags", "governance"]
---

# Snowflake Platform Engineering Power

This power provides Snowflake-specific DDL patterns and best practices for building enterprise data platforms.

## When to Load Steering Files

- Writing Snowflake infrastructure SQL (databases, warehouses, roles, grants) → `infrastructure-patterns.md`
- Creating semantic views for Cortex Analyst → `semantic-and-cortex.md`
- Writing governance SQL (tags, masking, row access policies) → `governance-patterns.md`
- Creating dynamic tables or streams/tasks → `realtime-patterns.md`
- Writing ingestion SQL (stages, COPY INTO, file formats) → `ingestion-patterns.md`

## Core Rules

- All DDL MUST use `CREATE OR REPLACE` or `CREATE ... IF NOT EXISTS` for idempotency
- All scripts MUST be executable repeatedly without error
- Warehouse references MUST use the appropriate workload warehouse (INGESTION_WH, TRANSFORM_WH, SERVING_WH, AI_WH)
- Role references MUST follow the hierarchy: LIGHTHOUSE_ADMIN → LIGHTHOUSE_ENGINEER → LIGHTHOUSE_TRANSFORMER → LIGHTHOUSE_READER
