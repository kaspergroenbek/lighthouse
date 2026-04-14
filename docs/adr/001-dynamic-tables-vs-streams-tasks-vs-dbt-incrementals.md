# ADR-001: Dynamic Tables vs Streams/Tasks vs dbt Incrementals

## Status
Accepted

## Context
Lighthouse needs to serve data at different freshness levels. Snowflake offers three mechanisms for incremental processing.

## Options
1. **dbt Incremental Models** — batch-scheduled, full governance (tests, docs, CI/CD), hourly+ latency
2. **Snowflake Dynamic Tables** — declarative SQL with `TARGET_LAG`, Snowflake-managed refresh, sub-minute possible
3. **Snowflake Streams + Tasks** — event-driven, most flexible but most complex

## Decision
Use dbt incrementals as default for all transformation layers. Use Dynamic Tables selectively for near-real-time serving where sub-5-minute freshness is needed. Reserve Streams/Tasks for operational automation only.

## Rationale
- dbt provides testing, documentation, lineage, and CI/CD — critical for governed data products
- Dynamic Tables fill the latency gap without scheduling infrastructure
- Streams/Tasks add complexity without dbt's governance benefits

## Consequences
- `device_latest_status` uses a Dynamic Table (5-min lag) in SERVING.REALTIME
- All mart-layer models use dbt incremental or table materialization
- Test alerting uses a Snowflake Task (operational, not transformation)
