# Ingestion Architecture — Simulation vs Production

## Overview

Lighthouse simulates five ingestion patterns using synthetic seed data and internal stages. This document maps each simulation to its production equivalent.

## 1. CDC Ingestion (OLTP → RAW.OLTP)

| Aspect | Simulation | Production |
|---|---|---|
| Source | Synthetic CSV files with `_op`, `_source_ts` columns | PostgreSQL WAL via managed CDC connector |
| Connector | `PUT` + `COPY INTO` from internal stage | Snowflake Openflow, Fivetran, or Airbyte |
| Latency | Manual/batch load | 15-minute target latency |
| Resume | Full reload each time | Offset-based resume from last committed LSN |
| Schema | Identical — CDC metadata columns preserved | Identical |

**To swap:** Replace `COPY INTO` with managed connector configuration pointing to PostgreSQL. Raw table schemas remain unchanged.

## 2. SaaS Ingestion (CRM → RAW.CRM)

| Aspect | Simulation | Production |
|---|---|---|
| Source | Synthetic CSV files with `_loaded_at`, `_sync_id`, `_is_deleted` | SaaS CRM API (Salesforce-like) |
| Connector | `PUT` + `COPY INTO` from internal stage | Fivetran or Airbyte managed SaaS connector |
| Frequency | Manual load | 60-minute sync frequency |
| Reconciliation | N/A | Daily full reconciliation to catch missed deletes |

**To swap:** Configure managed SaaS connector with API credentials. Raw table schemas remain unchanged.

## 3. Batch File Ingestion (Partner Feeds → RAW.PARTNER_FEEDS)

| Aspect | Simulation | Production |
|---|---|---|
| Source | Synthetic CSV/Parquet in `data/partner_feeds/` | Partner files on S3 bucket |
| Stage | Internal stage via `PUT` | External stage with S3 storage integration |
| Loading | Manual `COPY INTO` | Snowpipe auto-ingest via S3 event notifications |
| Archive | N/A | Move processed files to `archive/` prefix |
| Error handling | Quarantine stage + error log table | Same |

**To swap:** Create external stage on S3, configure Snowpipe with `AUTO_INGEST = TRUE`.

## 4. Streaming Ingestion (IoT → RAW.IOT)

| Aspect | Simulation | Production |
|---|---|---|
| Source | Synthetic JSON files in `data/iot_events/` | Device telemetry via MQTT/Kafka |
| Loading | `PUT` + `COPY INTO` with VARIANT parsing | Snowpipe Streaming API or Kafka connector |
| Latency | Manual/batch | 5-minute target latency |
| Backpressure | N/A | Kafka consumer group lag monitoring |

**To swap:** Configure Snowpipe Streaming API or Kafka connector. Raw table schema remains unchanged.

## 5. Unstructured Content (Knowledge Base → RAW.KNOWLEDGE_BASE)

| Aspect | Simulation | Production |
|---|---|---|
| Source | Markdown/text files | PDF, DOCX, Markdown documents |
| Text extraction | String functions on pre-formatted text | `PARSE_DOCUMENT()` for binary formats |
| Chunking | Stored procedure (~512 tokens, 50-token overlap) | Same |

**To swap:** Use `PARSE_DOCUMENT()` for binary formats. Chunking and search indexing remain unchanged.
