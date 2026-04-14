# Lighthouse Demo Guide

## Elevator Pitch (30 seconds)

Lighthouse is a production-grade data platform for NordHjem Energy — a Nordic connected-home and energy services company. It demonstrates how Snowflake + dbt can power governed, AI-ready data products from five different source systems, all the way through to a Cortex Analyst natural-language interface and a Streamlit app.

Everything runs on a Snowflake Enterprise trial account with synthetic data. The schemas are production-correct — swap the seed CSVs for real connectors and you have a real platform.

---

## Demo Flow (Recommended Order)

### 1. The Problem (2 min)
- NordHjem has **five disconnected source systems**: OLTP (PostgreSQL), SaaS CRM, IoT telemetry, partner feeds, and an unstructured knowledge base.
- No unified customer view. Billing, devices, and service tickets live in silos.
- **Highlight**: Show the `data/` directory — five subdirectories, five different formats (CSV, JSON, Markdown). This is the messy reality.

### 2. Ingestion Layer (3 min)
- Snowflake handles all ingestion via internal stages + `COPY INTO`.
- Five patterns demonstrated:

| Pattern | Source | Format | Landing Schema |
|---------|--------|--------|----------------|
| CDC simulation | PostgreSQL OLTP | CSV | `RAW.OLTP` |
| SaaS connector | CRM | CSV | `RAW.CRM` |
| Streaming | IoT devices | JSON (VARIANT) | `RAW.IOT` |
| Batch files | Partner feeds | CSV/Parquet | `RAW.PARTNER_FEEDS` |
| Unstructured | Knowledge base | Markdown/text | `RAW.KNOWLEDGE_BASE` |

- **Highlight**: The IoT data uses VARIANT columns — show how semi-structured JSON lands natively in Snowflake.

### 3. Three-Layer dbt Transformation (5 min)
- **Staging**: Source-conforming. No business logic. Just rename, cast, deduplicate.
- **Intermediate**: Business logic lives here. Cross-source joins, calculations. `protected` access.
- **Marts**: Kimball star schema with enforced model contracts and `public` access.
- **Highlight**: Model contracts, access controls, and domain groups — this is data mesh preparation.

### 4. Six Data Products (3 min)
1. **Customer 360** — Unified customer profile across all sources
2. **Contract & Revenue** — `fct_invoices`, `fct_payments`, `fct_contract_lifecycle`
3. **Device & Usage** — `fct_energy_usage_daily`, `fct_device_telemetry`
4. **Service Operations** — `fct_service_ticket_lifecycle`
5. **Reference & Semantic** — Conformed dimensions (`dim_customer`, `dim_date`, etc.)
6. **AI-Ready Knowledge** — Chunked documents for Cortex Search

### 5. Governance (3 min)
- Object Tags, Dynamic Data Masking, Row Access Policies.
- **Highlight**: Run a query as two different roles — same table, different data.

### 6. Dual Semantic Layer (3 min)
- dbt Semantic Layer (MetricFlow) for BI tools + Snowflake Semantic Views for Cortex Analyst.
- **Highlight**: Same business logic, two consumption paths.

### 7. Cortex AI Features (3 min)
- **Cortex Analyst**: "What was total revenue by region last quarter?"
- **Cortex Search**: "How do I troubleshoot a smart thermostat?"

### 8. Streamlit App (2 min)
- Runs inside Snowflake. No external infrastructure.

### 9. CI/CD & Testing (2 min)
- GitHub Actions: CI on PR (`state:modified+`), CD on merge.
- Unit tests, source freshness, Elementary observability.

---

## Key Talking Points

- **"Production-correct schemas"**: Synthetic data, real architecture.
- **"Data mesh ready"**: Domain groups + access controls + contracts.
- **"AI-ready, not AI-dependent"**: Cortex is an accelerator, not a requirement.
- **"Governance is built in, not bolted on"**: Tags, masking, RLS in infrastructure scripts.

---

## Common Questions & Answers

**Q: Why synthetic data?**
A: Runs on any Snowflake trial. No PII. Schemas transfer directly to production.

**Q: Why a single dbt project?**
A: MVP simplicity. Domain groups and access controls prepare for future data mesh decomposition.

**Q: Why both dbt Semantic Layer and Snowflake Semantic Views?**
A: MetricFlow serves BI tools. Semantic Views serve Cortex Analyst. Same metrics, two interfaces.

**Q: How does the IoT data work?**
A: JSON events land in VARIANT columns. Staging flattens. Downstream aggregates into daily/telemetry facts.

**Q: What about real-time?**
A: Dynamic Tables in `SERVING.REALTIME` with configurable target lag. Near-real-time, not true streaming.
