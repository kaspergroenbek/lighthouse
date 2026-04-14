# ADR-003: Managed vs Custom Ingestion

## Status
Accepted

## Context
Lighthouse ingests from five source types. Each could use managed connectors or custom pipelines.

## Decision
Managed connectors for CDC (OLTP) and SaaS (CRM). Snowflake-native features (Snowpipe, COPY INTO) for batch, streaming, and unstructured.

## Rationale
- CDC/SaaS connectors are commodity — managed tools handle schema drift, retries, offsets
- Batch/streaming benefits from Snowflake-native features without external dependencies
- Unstructured uses `PARSE_DOCUMENT()` and stored procedures natively

## Consequences
- CDC/CRM depend on a connector vendor (Fivetran/Airbyte)
- Batch/streaming are fully Snowflake-native
- Demo environment simulates all ingestion with seed files
