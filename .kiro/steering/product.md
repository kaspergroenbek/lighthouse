# Product: Lighthouse

Lighthouse is a portfolio-grade, AI-ready data product platform built on Snowflake and dbt for a fictional Nordic connected-home and energy services company called **NordHjem Energy**.

NordHjem Energy provides connected-home energy management, smart device installations, service contracts, and sustainability advisory across the Nordics. Source systems include a PostgreSQL OLTP (contracts/billing), a SaaS CRM, IoT telemetry from smart devices, partner data feeds, and an unstructured knowledge base.

The platform separates **platform enablement** (governed data products, semantic interfaces, AI-ready serving) from **business analytics delivery** (dashboards, reports). Lighthouse builds the foundation; downstream consumers build on top.

## Key Capabilities

- Five simulated ingestion patterns: CDC, SaaS, batch files, streaming IoT, unstructured documents
- Three-layer dbt ELT: staging → intermediate → marts (Kimball star schema)
- Six governed data products: Customer 360, Contract & Revenue, Device & Usage, Service Operations, Reference & Semantic, AI-Ready Knowledge
- Dual semantic layer: dbt Semantic Layer (MetricFlow) for BI tools + Snowflake semantic views for Cortex Analyst
- Cortex Search over chunked knowledge base documents
- Governance: classification tags, dynamic masking, row-level security, comprehensive testing
- Streamlit in Snowflake demo app

## Important Context

- All data is synthetic/fictional — designed to run on a Snowflake Enterprise trial account
- Ingestion is simulated via seed CSVs and internal stages, but schemas are production-correct so swapping to real connectors only changes the ingestion mechanism
- Single dbt project for MVP, with domain-aligned groups and model access controls preparing for future data mesh decomposition
