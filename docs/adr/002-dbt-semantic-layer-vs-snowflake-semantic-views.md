# ADR-002: dbt Semantic Layer vs Snowflake Semantic Views

## Status
Accepted

## Context
Lighthouse needs governed metric definitions accessible to both BI tools and Snowflake-native AI features (Cortex Analyst).

## Options
1. **dbt Semantic Layer only** — MetricFlow metrics via dbt SL API
2. **Snowflake Semantic Views only** — `CREATE SEMANTIC VIEW` for Cortex Analyst
3. **Dual semantic layer** — both, sharing the same physical mart tables

## Decision
Dual semantic layer: dbt MetricFlow for BI tools, Snowflake Semantic Views for Cortex Analyst.

## Rationale
- dbt SL integrates with Tableau/Looker/Mode; Snowflake semantic views don't
- Cortex Analyst requires Snowflake-native semantic views; it can't consume MetricFlow
- Both read from the same physical marts — no data duplication
- See `docs/semantic-layer-mapping.md` for the metric mapping

## Consequences
- Metric definitions exist in two places — requires discipline to keep aligned
- New metrics should be added to both layers when applicable
