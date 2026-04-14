# ADR-005: dbt Core vs dbt Cloud vs Snowflake-Native

## Status
Accepted

## Context
Lighthouse needs a dbt deployment strategy for a consultancy context with varying client environments.

## Decision
dbt Core with GitHub Actions for CI/CD. Document dbt Cloud as an upgrade path for managed scheduling and hosted semantic layer.

## Rationale
- dbt Core is free, portable, works with any Snowflake account
- GitHub Actions provides sufficient CI/CD for MVP
- dbt Cloud adds managed scheduler, IDE, and hosted SL API — valuable for production teams
- Snowflake-native dbt not yet GA — monitor for future adoption

## Consequences
- No managed scheduler — builds triggered by GitHub Actions
- Semantic Layer API requires dbt Cloud — documented as upgrade path
- All artifacts compatible with both Core and Cloud
