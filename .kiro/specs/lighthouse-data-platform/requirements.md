# Requirements Document — Lighthouse: AI-Ready Data Product Platform on Snowflake + dbt

## Introduction

Lighthouse is a portfolio-grade, fully implementable data platform designed for a fictional Nordic connected-home and energy services company called **NordHjem Energy**. The platform demonstrates senior data engineering judgment across Snowflake, dbt, Kimball dimensional modeling, hybrid ingestion, data product design, and AI-readiness. It is built to be lifted and shifted into a real Snowflake account and dbt project.

The platform separates **platform enablement** (governed data products, semantic interfaces, AI-ready serving) from **business analytics delivery** (dashboards, reports). Lighthouse builds the foundation; downstream consumers build on top.

**Fictional Company Context:** NordHjem Energy provides connected-home energy management, smart device installations, service contracts, and sustainability advisory services across the Nordics. They operate an OLTP system for contracts and billing, a CRM for customer interactions, IoT telemetry from smart devices, partner data feeds, and a knowledge base of manuals and service documentation.

## Glossary

- **Platform**: The Lighthouse data platform comprising Snowflake infrastructure, dbt transformation project, ingestion pipelines, governance controls, and serving interfaces
- **Ingestion_Layer**: The Snowflake-native landing zone where raw data arrives from source systems before any transformation
- **Staging_Layer**: The dbt-owned layer that applies source-conforming standardization (renaming, casting, deduplication) without business logic
- **Intermediate_Layer**: The dbt-owned layer that applies business logic, joins, and harmonization across sources
- **Marts_Layer**: The dbt-owned dimensional model layer containing conformed dimensions and fact tables organized by business domain
- **Semantic_Layer**: The combined dbt Semantic Layer (metrics/dimensions) and Snowflake semantic views that expose governed, query-ready interfaces
- **Data_Product**: A self-contained, governed, versioned, contractually defined data asset with explicit purpose, owner, consumers, grain, freshness SLA, and quality expectations
- **Bus_Matrix**: The Kimball enterprise bus matrix mapping business processes (facts) to conformed dimensions
- **Conformed_Dimension**: A dimension shared across multiple fact tables with consistent keys, attributes, and grain
- **SCD**: Slowly Changing Dimension — a strategy for tracking historical changes in dimension attributes
- **Surrogate_Key**: A platform-generated synthetic key (hash or sequence) that uniquely identifies dimension records independent of source natural keys
- **Natural_Key**: The business-meaningful identifier from the source system (e.g., customer_id, device_serial_number)
- **CDC**: Change Data Capture — a pattern for capturing row-level inserts, updates, and deletes from source systems
- **Dynamic_Table**: A Snowflake-native object that declaratively defines a transformation query and a target lag, with Snowflake managing refresh automatically
- **Stream**: A Snowflake object that tracks DML changes (inserts, updates, deletes) on a table, view, or dynamic table
- **Task**: A Snowflake object that executes SQL or stored procedures on a schedule or in response to a stream
- **Cortex_Analyst**: Snowflake's AI feature enabling natural-language querying over semantic models
- **Cortex_Search**: Snowflake's AI feature enabling semantic search over unstructured text content
- **dbt_Semantic_Layer**: The MetricFlow-based semantic layer in dbt that defines reusable metrics, dimensions, and entities for governed analytics
- **Snowflake_Semantic_View**: A Snowflake-native semantic model definition (YAML) that enables Cortex Analyst to answer natural-language questions
- **Model_Contract**: A dbt feature that enforces column names, data types, and constraints on a model, preventing breaking changes
- **Model_Version**: A dbt feature that allows multiple versions of a model to coexist, enabling non-breaking schema evolution
- **Model_Access**: A dbt feature (public/protected/private) that controls which models can be referenced by other dbt projects or groups
- **Exposure**: A dbt object that documents downstream consumers of dbt models (dashboards, ML pipelines, applications)
- **NordHjem_OLTP**: The PostgreSQL transactional database for NordHjem Energy's contracts, billing, customers, and installations
- **NordHjem_CRM**: The SaaS CRM platform (Salesforce-like) used for customer interactions, service tickets, and sales pipeline
- **NordHjem_IoT**: The streaming telemetry pipeline from smart home devices (thermostats, meters, sensors)
- **Partner_Feeds**: Batch CSV/Parquet files from energy grid operators and installation partners delivered to cloud object storage
- **Knowledge_Base**: Unstructured documents including product manuals, service procedures, policy documents, and support articles

## Requirements

### Requirement 1: Snowflake Infrastructure and Environment Strategy

**User Story:** As a platform engineer, I want a reproducible Snowflake infrastructure setup with clear environment separation, so that the platform can be deployed consistently across development, staging, and production.

#### Acceptance Criteria

1. THE Platform SHALL provision Snowflake databases following the naming convention `LIGHTHOUSE_{ENV}_{LAYER}` (e.g., `LIGHTHOUSE_PROD_RAW`, `LIGHTHOUSE_PROD_ANALYTICS`) for each logical layer and environment (DEV, STAGING, PROD).
2. THE Platform SHALL provision Snowflake warehouses sized and configured per workload type: `INGESTION_WH` (X-Small, auto-suspend 60s), `TRANSFORM_WH` (Small, auto-suspend 120s), `SERVING_WH` (Small, auto-suspend 60s), `AI_WH` (Medium, auto-suspend 120s, used for Cortex workloads).
3. THE Platform SHALL define all infrastructure as idempotent SQL scripts organized by concern (databases, warehouses, roles, grants, stages, integrations) that can be executed repeatedly without error.
4. THE Platform SHALL implement a role hierarchy following Snowflake's recommended pattern: `LIGHTHOUSE_ADMIN` → `LIGHTHOUSE_ENGINEER` → `LIGHTHOUSE_TRANSFORMER` → `LIGHTHOUSE_READER`, with each role inheriting privileges from the role below it.
5. WHEN a new environment is provisioned, THE Platform SHALL create all required databases, schemas, warehouses, roles, and grants from a single orchestration script that calls the individual concern scripts in dependency order.
6. THE Platform SHALL create Snowflake storage integrations for AWS S3 (or Azure Blob) to support external stage access for batch file ingestion and unstructured content loading.
7. THE Platform SHALL create Snowflake API integrations where required for SaaS connector authentication and Cortex AI feature access.

---

### Requirement 2: CDC Ingestion from OLTP Source (PostgreSQL)

**User Story:** As a data engineer, I want to ingest change data from the NordHjem PostgreSQL OLTP system into Snowflake with minimal latency, so that the platform reflects near-real-time transactional state.

**Simulation Note:** In the demo/trial environment, CDC ingestion is simulated using synthetic seed CSV files loaded via COPY INTO or dbt seeds that mimic the structure and metadata of a real CDC stream (including operation type, source timestamps, and multiple change records per key). The architecture, raw table schemas, and downstream models are designed as if a managed CDC connector (Snowflake Openflow, Fivetran, or Airbyte) is producing the data. Documentation explains how to swap the simulation for a real connector in production.

#### Acceptance Criteria

1. THE Ingestion_Layer SHALL define raw table schemas in `RAW.OLTP` that match the output format of a managed CDC connector, including columns for operation type (`INSERT`, `UPDATE`, `DELETE`), source timestamp, all source columns, `_loaded_at`, and `_connector_batch_id`.
2. THE Platform SHALL provide synthetic CDC seed data (CSV files) for all OLTP entities that include realistic change history: multiple records per natural key showing inserts, updates, and at least one delete, with realistic timestamps spanning multiple days.
3. THE Platform SHALL load synthetic CDC data into `RAW.OLTP` tables using COPY INTO from internal stages or dbt seeds, simulating the landing pattern of a managed connector.
4. THE Ingestion_Layer SHALL ingest at minimum these entity tables from NordHjem_OLTP: `customers`, `households`, `installations`, `devices`, `contracts`, `tariff_plans`, `products`, `services`, `invoices`, `invoice_line_items`, `payments`.
5. THE Platform SHALL document the production ingestion architecture (managed CDC connector with resume-from-offset capability, 15-minute target latency) alongside the simulation approach, so that a reviewer understands both the demo path and the production path.
6. THE Ingestion_Layer SHALL store raw CDC data with a `_loaded_at` metadata timestamp and `_connector_batch_id` column for lineage traceability, even in the simulated environment.

---

### Requirement 3: SaaS Ingestion from CRM Platform

**User Story:** As a data engineer, I want to ingest customer interaction and service data from the NordHjem CRM (SaaS) into Snowflake, so that service operations and customer 360 data products have complete interaction history.

**Simulation Note:** In the demo/trial environment, CRM ingestion is simulated using synthetic seed CSV files loaded via COPY INTO or dbt seeds that mimic the output of a managed SaaS connector (Fivetran/Airbyte). The raw table schemas include connector-style metadata columns (`_loaded_at`, `_sync_id`, `_is_deleted`). Documentation explains how to replace the simulation with a real connector.

#### Acceptance Criteria

1. THE Ingestion_Layer SHALL define raw table schemas in `RAW.CRM` that match the output format of a managed SaaS connector, including `_loaded_at`, `_sync_id`, and `_is_deleted` metadata columns.
2. THE Platform SHALL provide synthetic CRM seed data (CSV files) for all CRM objects that include realistic data: multiple sync batches, soft-deleted records, and incremental changes over time.
3. THE Platform SHALL load synthetic CRM data into `RAW.CRM` tables using COPY INTO from internal stages or dbt seeds, simulating the landing pattern of a managed connector.
4. THE Ingestion_Layer SHALL ingest at minimum these CRM objects: `accounts`, `contacts`, `cases` (service tickets), `case_comments`, `opportunities`, `tasks`, `campaigns`, `campaign_members`.
5. THE Platform SHALL document the production ingestion architecture (managed SaaS connector with 60-minute sync frequency, daily full reconciliation, retry logic) alongside the simulation approach.
6. THE Ingestion_Layer SHALL store raw CRM data with `_loaded_at`, `_sync_id`, and `_is_deleted` metadata columns to support soft-delete tracking and lineage, even in the simulated environment.

---

### Requirement 4: Batch File Ingestion from Object Storage and Partner Feeds

**User Story:** As a data engineer, I want to ingest batch files from cloud object storage (partner feeds, grid operator data), so that external data sources are integrated into the platform on a scheduled basis.

**Simulation Note:** In the demo/trial environment, batch file ingestion is simulated using synthetic CSV/Parquet files loaded from Snowflake internal stages via COPY INTO. External stages (S3) and Snowpipe auto-ingest are not available on trial accounts without external network access, so the demo uses internal stages with manual or Task-scheduled COPY INTO. The file formats, raw table schemas, and metadata columns are production-correct.

#### Acceptance Criteria

1. THE Ingestion_Layer SHALL ingest batch files from Snowflake internal stages using the COPY INTO command, with file format objects defined per source partner in the `RAW.PARTNER_FEEDS` schema.
2. THE Ingestion_Layer SHALL support CSV and Parquet file formats with explicit file format definitions (delimiter, skip_header, compression, column mapping).
3. THE Platform SHALL provide synthetic partner feed files in the repository under a `data/partner_feeds/` directory, loadable to internal stages via PUT command.
4. THE Ingestion_Layer SHALL ingest at minimum these partner feed types: `grid_usage_readings` (energy grid operator, daily CSV), `installation_certifications` (partner installers, weekly Parquet), `product_catalog_updates` (manufacturer, monthly CSV).
5. THE Ingestion_Layer SHALL land all batch files into raw tables with `_loaded_at`, `_source_file_name`, `_source_file_row_number` metadata columns for full file-level lineage.
6. IF a batch file fails schema validation or contains corrupt records, THEN THE Ingestion_Layer SHALL route the file to a quarantine stage and log the failure with file name, error type, and record count for operations review.
7. THE Platform SHALL document the production ingestion architecture (external stages on S3, Snowpipe auto-ingest, archive patterns) alongside the simulation approach using internal stages.

---

### Requirement 5: Streaming Ingestion from IoT Devices and Telemetry

**User Story:** As a data engineer, I want to ingest streaming telemetry events from NordHjem smart home devices into Snowflake, so that device usage and energy data is available for near-real-time data products.

**Simulation Note:** In the demo/trial environment, streaming ingestion is simulated using synthetic JSON telemetry event files loaded from internal stages via COPY INTO with VARIANT parsing. The raw table schemas, metadata columns, and semi-structured handling are production-correct. Documentation explains how to replace the simulation with Snowpipe Streaming API or Kafka connector in production.

#### Acceptance Criteria

1. THE Ingestion_Layer SHALL define raw tables in `RAW.IOT` with a semi-structured VARIANT column alongside extracted metadata columns (`device_id`, `event_type`, `event_timestamp`, `_loaded_at`).
2. THE Platform SHALL provide synthetic telemetry event data as JSON files in the repository under a `data/iot_events/` directory, loadable to internal stages via PUT command.
3. THE Platform SHALL load synthetic IoT data into `RAW.IOT` tables using COPY INTO with VARIANT column parsing, simulating the landing pattern of a streaming ingestion pipeline.
4. THE Ingestion_Layer SHALL support at minimum these telemetry event types: `energy_reading` (periodic meter readings), `device_status` (heartbeat/health), `temperature_reading` (thermostat data), `alert_event` (threshold breaches, device faults).
5. THE Ingestion_Layer SHALL handle out-of-order and late-arriving events by preserving the source `event_timestamp` separately from the `_loaded_at` platform timestamp, enabling downstream deduplication and reordering.
6. THE Platform SHALL document the production ingestion architecture (Snowpipe Streaming API or Kafka connector, 5-minute target latency, backpressure handling, offset-based resume) alongside the simulation approach.
7. THE Ingestion_Layer SHALL partition raw IoT data by ingestion date to support efficient pruning and lifecycle management given the high volume of telemetry events.


---

### Requirement 6: Unstructured Content Ingestion for Knowledge Base

**User Story:** As a data engineer, I want to ingest unstructured documents (manuals, service procedures, policies, support articles) into Snowflake, so that they can be indexed for AI-powered semantic search and retrieval.

**Simulation Note:** In the demo/trial environment, unstructured content is simulated using synthetic Markdown and plain text documents loaded to Snowflake internal stages. Text extraction uses Snowflake-native string functions on the pre-formatted text content rather than PARSE_DOCUMENT on binary PDFs. The chunking logic, tracking table, and Cortex Search integration are production-correct.

#### Acceptance Criteria

1. THE Ingestion_Layer SHALL load unstructured documents from Snowflake internal stages and register them in a `RAW.KNOWLEDGE_BASE` tracking table.
2. THE Platform SHALL provide synthetic knowledge base documents (Markdown and plain text) in the repository under a `data/knowledge_base/` directory, covering at minimum: 2 product manuals, 2 service procedures, 1 policy document, and 2 support articles.
3. THE Ingestion_Layer SHALL support at minimum Markdown and plain text document formats for knowledge base content in the demo environment, with documentation noting PDF support via PARSE_DOCUMENT in production.
4. THE Platform SHALL register each document in the tracking table with metadata: `document_id`, `file_name`, `file_type`, `source_path`, `_loaded_at`, `category` (manual, procedure, policy, support_article).
5. THE Platform SHALL extract text content from documents and store the extracted text in a structured table alongside the document metadata.
6. THE Platform SHALL chunk extracted document text into segments of approximately 512 tokens with 50-token overlap for downstream embedding and search indexing.
7. IF a document fails text extraction, THEN THE Platform SHALL log the failure with document_id, error type, and retain the original file in the stage for manual review.

---

### Requirement 7: dbt Staging Layer — Source-Conforming Standardization

**User Story:** As a data engineer, I want a dbt staging layer that standardizes raw source data with consistent naming, typing, and deduplication, so that downstream models have a clean, reliable foundation.

#### Acceptance Criteria

1. THE Staging_Layer SHALL contain one dbt staging model per source entity table, following the naming convention `stg_{source_system}__{entity_name}` (e.g., `stg_oltp__customers`, `stg_crm__cases`, `stg_iot__energy_readings`).
2. THE Staging_Layer SHALL apply column renaming to snake_case, data type casting to platform-standard types, and column reordering (keys first, attributes, metadata last) without applying business logic or cross-source joins.
3. WHEN CDC source data contains multiple change records for the same natural key, THE Staging_Layer SHALL deduplicate to the latest record per natural key using the source timestamp and operation type, filtering out deleted records into a separate `_deleted` model where needed.
4. THE Staging_Layer SHALL define dbt sources with freshness checks for each raw schema (`RAW.OLTP`, `RAW.CRM`, `RAW.IOT`, `RAW.PARTNER_FEEDS`), with warn and error thresholds appropriate to each source's expected refresh frequency.
5. THE Staging_Layer SHALL apply not-null tests on all primary key columns and unique tests on natural key columns for every staging model.
6. THE Staging_Layer SHALL use dbt model configurations appropriate to source volume: `incremental` materialization with `_loaded_at` filtering for high-volume sources (IoT telemetry, CDC), `view` materialization for low-volume reference sources (product catalog, tariff plans).

---

### Requirement 8: dbt Intermediate Layer — Business Logic and Harmonization

**User Story:** As a data engineer, I want a dbt intermediate layer that applies business logic, cross-source joins, and entity harmonization, so that the dimensional marts layer receives clean, business-aligned entities.

#### Acceptance Criteria

1. THE Intermediate_Layer SHALL contain dbt models following the naming convention `int_{domain}__{description}` (e.g., `int_customer__unified_profile`, `int_billing__invoice_enriched`).
2. THE Intermediate_Layer SHALL resolve entity matching across sources: unifying customer records from NordHjem_OLTP and NordHjem_CRM using a deterministic matching strategy based on shared natural keys (email, customer_id) with explicit handling of non-matches.
3. THE Intermediate_Layer SHALL apply business logic transformations including: contract status derivation, device lifecycle state calculation, revenue classification, service ticket severity mapping, and telemetry aggregation windows.
4. THE Intermediate_Layer SHALL compute derived fields that require cross-source context, such as customer lifetime value inputs, device health scores, and contract renewal eligibility flags.
5. THE Intermediate_Layer SHALL use `ephemeral` or `view` materialization for lightweight transformation models and `table` or `incremental` materialization for heavy aggregation or cross-source join models, with explicit configuration per model.
6. THE Intermediate_Layer SHALL set model access to `protected` (accessible within the dbt project but not exposed as a data product interface).

---

### Requirement 9: dbt Dimensional Marts — Kimball Star Schema

**User Story:** As a data engineer, I want a Kimball-style dimensional model in the dbt marts layer with conformed dimensions, multiple fact table types, and an enterprise bus matrix, so that the platform delivers analytically optimized, governed data products.

#### Acceptance Criteria

1. THE Marts_Layer SHALL implement an enterprise bus matrix mapping at minimum these business processes to conformed dimensions:

   | Business Process (Fact) | Customer | Household | Device | Product | Contract | Date | Time |
   |---|---|---|---|---|---|---|---|
   | Invoicing | X | X | | X | X | X | |
   | Payments | X | X | | | X | X | |
   | Energy Usage | X | X | X | X | | X | X |
   | Service Interactions | X | X | X | | X | X | |
   | Device Telemetry | | X | X | | | X | X |
   | Contract Lifecycle | X | X | | X | X | X | |

2. THE Marts_Layer SHALL implement at minimum these conformed dimensions with surrogate keys (generated via `dbt_utils.generate_surrogate_key`), natural keys, and descriptive attributes:
   - `dim_customer` (grain: one row per customer)
   - `dim_household` (grain: one row per household/site/installation)
   - `dim_device` (grain: one row per physical device)
   - `dim_product` (grain: one row per product or service offering)
   - `dim_contract` (grain: one row per contract version)
   - `dim_date` (grain: one row per calendar date, generated via dbt seed or macro)
   - `dim_time` (grain: one row per minute of day, for telemetry granularity)

3. THE Marts_Layer SHALL implement at minimum one transaction fact table (`fct_invoices` — grain: one row per invoice line item) recording individual billing events with foreign keys to dim_customer, dim_household, dim_product, dim_contract, dim_date, and additive measures (amount, quantity, tax).

4. THE Marts_Layer SHALL implement at minimum one periodic snapshot fact table (`fct_energy_usage_daily` — grain: one row per device per day) aggregating telemetry readings into daily energy consumption, peak usage, average temperature, and reading count measures.

5. THE Marts_Layer SHALL implement at minimum one accumulating snapshot fact table (`fct_service_ticket_lifecycle` — grain: one row per service ticket) tracking milestone dates (opened_at, assigned_at, first_response_at, resolved_at, closed_at) and durations between milestones.

6. THE Marts_Layer SHALL implement SCD Type 2 for `dim_customer` and `dim_contract` using dbt snapshots with `valid_from`, `valid_to`, and `is_current` columns, and SCD Type 1 (overwrite) for `dim_product` and `dim_device` where historical attribute tracking is not business-critical.

7. THE Marts_Layer SHALL implement a bridge table `bridge_household_device` (grain: one row per household-device assignment period) to resolve the many-to-many relationship between households and devices over time, with `effective_from` and `effective_to` date columns.

8. THE Marts_Layer SHALL generate surrogate keys using a deterministic hash strategy (`dbt_utils.generate_surrogate_key`) based on natural key columns, ensuring reproducibility across full refreshes.

9. THE Marts_Layer SHALL enforce model contracts on all dimension and fact tables, specifying column names, data types, and not-null constraints for key columns.

10. THE Marts_Layer SHALL set model access to `public` for all dimension and fact tables intended for data product consumption, and document each model with descriptions, column descriptions, and grain statements.

---

### Requirement 10: dbt Snapshots for Slowly Changing Dimensions

**User Story:** As a data engineer, I want dbt snapshots that capture historical changes in key business entities, so that the dimensional model can accurately represent SCD Type 2 dimensions.

#### Acceptance Criteria

1. THE Platform SHALL implement dbt snapshots for at minimum `customers` and `contracts` source entities, using the `timestamp` snapshot strategy based on the source system's `updated_at` column.
2. WHEN a tracked attribute changes in the source system, THE snapshot SHALL close the previous record (set `dbt_valid_to` to the change timestamp) and insert a new record with the updated attributes and `dbt_valid_from` set to the change timestamp.
3. THE Platform SHALL configure snapshots to target a dedicated `SNAPSHOTS` schema in the analytics database, separate from staging and marts schemas.
4. THE Platform SHALL include `dbt_valid_from`, `dbt_valid_to`, `dbt_scd_id`, and `dbt_updated_at` metadata columns on all snapshot tables.
5. THE Platform SHALL schedule snapshot execution as part of the dbt build DAG, running after staging models and before intermediate/marts models that depend on historical dimension data.


---

### Requirement 11: Data Products — Customer 360

**User Story:** As a data product owner, I want a Customer 360 data product that provides a unified, governed view of each customer across all source systems, so that downstream consumers (AI models, service applications, analytics) have a single trusted customer entity.

#### Acceptance Criteria

1. THE Data_Product SHALL expose a `customer_360` interface at the grain of one row per customer, combining attributes from NordHjem_OLTP (demographics, account status), NordHjem_CRM (interaction history summary, satisfaction scores), and derived metrics (lifetime value inputs, contract count, active device count).
2. THE Data_Product SHALL refresh within 60 minutes of source data changes during business hours.
3. THE Data_Product SHALL enforce a dbt model contract specifying all column names, data types, and not-null constraints on key columns.
4. THE Data_Product SHALL apply column-level classification tags (`PII`, `SENSITIVE`, `PUBLIC`) using Snowflake object tagging on columns containing personal data (name, email, phone, address).
5. THE Data_Product SHALL apply dynamic data masking on PII columns so that the `LIGHTHOUSE_READER` role sees masked values while `LIGHTHOUSE_ENGINEER` and above see full values.
6. THE Data_Product SHALL include dbt documentation with: purpose statement, producer/owner (Customer Domain Team), intended consumers (AI models, service apps, analytics teams), grain definition, freshness SLA (60 min), and quality expectations (unique customer_sk, not-null on key fields, referential integrity to dim_customer).

---

### Requirement 12: Data Products — Contract and Revenue

**User Story:** As a data product owner, I want a Contract and Revenue data product that provides governed access to contract lifecycle, invoicing, and payment data, so that revenue analytics and financial reporting consumers have a trusted source.

#### Acceptance Criteria

1. THE Data_Product SHALL expose contract and revenue interfaces including: `fct_invoices`, `fct_payments` (transaction facts), `fct_contract_lifecycle` (accumulating snapshot tracking contract stages: created, activated, renewed, cancelled), and `dim_contract` (SCD2).
2. THE Data_Product SHALL define the grain explicitly for each interface: `fct_invoices` at invoice line item, `fct_payments` at individual payment, `fct_contract_lifecycle` at contract version.
3. THE Data_Product SHALL refresh within 60 minutes of source data changes.
4. THE Data_Product SHALL enforce model contracts and model versioning (starting at v1) on all public-facing models, enabling non-breaking schema evolution.
5. THE Data_Product SHALL include dbt exposures documenting at minimum one example downstream consumer (e.g., "Revenue Reporting Dashboard" or "Contract Renewal Prediction Model").
6. THE Data_Product SHALL apply row-level security using Snowflake row access policies so that regional data access is restricted based on the querying role's assigned region attribute.

---

### Requirement 13: Data Products — Device and Usage

**User Story:** As a data product owner, I want a Device and Usage data product that provides governed access to device telemetry, energy consumption, and device health data, so that IoT analytics and operational monitoring consumers have a trusted source.

#### Acceptance Criteria

1. THE Data_Product SHALL expose device and usage interfaces including: `fct_energy_usage_daily` (periodic snapshot), `fct_device_telemetry` (transaction-level telemetry events), `dim_device`, and `dim_household`.
2. THE Data_Product SHALL define the grain explicitly: `fct_energy_usage_daily` at device-day, `fct_device_telemetry` at individual telemetry event.
3. THE Data_Product SHALL refresh the daily periodic snapshot within 120 minutes of the end of each calendar day, and the telemetry transaction fact within 30 minutes of event ingestion.
4. THE Data_Product SHALL enforce model contracts on all public-facing models.
5. THE Data_Product SHALL include quality tests: accepted range tests on energy readings (0–9999 kWh), recency tests on telemetry data, and referential integrity tests between facts and dimensions.
6. THE Data_Product SHALL include dbt documentation with one example downstream use: "Device Health Anomaly Detection Model" consuming fct_device_telemetry to identify devices with degrading performance patterns.

---

### Requirement 14: Data Products — Service Operations

**User Story:** As a data product owner, I want a Service Operations data product that provides governed access to service ticket lifecycle, resolution metrics, and customer interaction data, so that service quality monitoring and workforce optimization consumers have a trusted source.

#### Acceptance Criteria

1. THE Data_Product SHALL expose service operations interfaces including: `fct_service_ticket_lifecycle` (accumulating snapshot), a service interaction summary model, and relevant conformed dimensions (dim_customer, dim_household, dim_device).
2. THE Data_Product SHALL define the grain of `fct_service_ticket_lifecycle` at one row per service ticket, tracking milestone timestamps and computed duration measures.
3. THE Data_Product SHALL refresh within 60 minutes of source CRM data changes.
4. THE Data_Product SHALL enforce model contracts and include dbt tests for: milestone date ordering (opened_at <= assigned_at <= first_response_at <= resolved_at <= closed_at), not-null on ticket_id, and accepted values for ticket status and severity.
5. THE Data_Product SHALL include dbt documentation with one example downstream use: "Service SLA Compliance Monitoring" consuming fct_service_ticket_lifecycle to measure first-response and resolution times against SLA targets.

---

### Requirement 15: Data Products — Reference and Semantic

**User Story:** As a data product owner, I want a Reference and Semantic data product that provides governed, shared reference data (date, time, product catalog, geography) and semantic definitions, so that all other data products use consistent reference entities.

#### Acceptance Criteria

1. THE Data_Product SHALL expose reference dimension interfaces including: `dim_date`, `dim_time`, `dim_product`, and a `dim_geography` (grain: one row per postal code / municipality).
2. THE Data_Product SHALL generate `dim_date` covering at minimum 10 years (2020–2030) with attributes: date_key, full_date, day_of_week, week_number (ISO), month, quarter, year, is_weekend, is_danish_public_holiday, fiscal_year, fiscal_quarter.
3. THE Data_Product SHALL generate `dim_time` covering all 1440 minutes of a day with attributes: time_key, hour, minute, time_of_day_band (morning, afternoon, evening, night), is_business_hour.
4. THE Data_Product SHALL implement `dim_date` and `dim_time` as dbt seeds or macro-generated models that are deterministic and reproducible.
5. THE Data_Product SHALL set model access to `public` on all reference dimensions and enforce model contracts.

---

### Requirement 16: Data Products — AI-Ready Knowledge Product

**User Story:** As a data product owner, I want an AI-Ready Knowledge Product that provides chunked, indexed, and searchable document content from the NordHjem knowledge base, so that Cortex Search and other AI consumers can perform semantic retrieval over manuals, procedures, and support articles.

#### Acceptance Criteria

1. THE Data_Product SHALL expose a `knowledge_chunks` table at the grain of one row per document chunk, containing: chunk_id, document_id, chunk_sequence_number, chunk_text, document_title, document_category, source_file_name, _loaded_at.
2. THE Data_Product SHALL ensure all chunks are derived from the text extraction and chunking pipeline defined in Requirement 6, with referential integrity to the document tracking table.
3. THE Data_Product SHALL create a Cortex Search service over the `knowledge_chunks` table, indexing on `chunk_text` with filterable attributes `document_category` and `document_title`.
4. THE Data_Product SHALL refresh the Cortex Search index within 24 hours of new document ingestion.
5. THE Data_Product SHALL include dbt documentation with one example downstream use: "Support Agent Copilot" using Cortex Search to retrieve relevant manual sections and troubleshooting procedures in response to natural-language queries from service agents.


---

### Requirement 17: dbt Semantic Layer — Governed Metrics

**User Story:** As a data engineer, I want a dbt Semantic Layer configuration that defines reusable, governed metrics and dimensions using MetricFlow, so that downstream analytics tools and consumers query consistent business metrics without redefining logic.

#### Acceptance Criteria

1. THE Semantic_Layer SHALL define MetricFlow semantic models for at minimum these mart models: `fct_invoices`, `fct_energy_usage_daily`, `fct_service_ticket_lifecycle`, `dim_customer`, `dim_date`.
2. THE Semantic_Layer SHALL define at minimum these governed metrics:
   - `total_revenue` (sum of invoice line item amounts)
   - `average_daily_energy_consumption` (average of daily kWh per device)
   - `median_first_response_time` (median duration from ticket opened to first response)
   - `active_customer_count` (count of distinct customers with active contracts)
   - `device_uptime_rate` (percentage of devices with status "online" in the latest telemetry window)
3. THE Semantic_Layer SHALL define dimensions and entities that enable slicing metrics by: customer, household, product, contract type, date (day/week/month/quarter/year), device type, and geography.
4. THE Semantic_Layer SHALL use dbt Semantic Layer YAML configuration files co-located with the mart models they describe.
5. THE Semantic_Layer SHALL include metric descriptions, owner annotations, and grain documentation for each semantic model.

---

### Requirement 18: Snowflake Semantic Views for Cortex Analyst

**User Story:** As a data engineer, I want Snowflake semantic view definitions that enable Cortex Analyst to answer natural-language questions over the dimensional model, so that business users can "talk to their data" without writing SQL.

#### Acceptance Criteria

1. THE Platform SHALL create a Snowflake semantic view using `CREATE SEMANTIC VIEW` SQL syntax for at minimum one "talk to your data" domain: the Contract and Revenue data product (covering fct_invoices, fct_payments, dim_customer, dim_contract, dim_product, dim_date).
2. THE Platform SHALL define the semantic view with: TABLES (with PRIMARY KEY), RELATIONSHIPS (join paths between facts and dimensions), FACTS (measures/aggregatable columns), DIMENSIONS (sliceable attributes with COMMENT and optional SYNONYMS), and METRICS (pre-defined aggregations).
3. THE Platform SHALL deploy the semantic view as a first-class Snowflake object in the `ANALYTICS.SEMANTIC` schema using an idempotent `CREATE OR REPLACE SEMANTIC VIEW` SQL script in the `snowflake/semantic/` directory.
4. THE Platform SHALL minimize duplication between dbt Semantic Layer metric definitions and Snowflake semantic view definitions by: using dbt marts as the single physical source for both, and documenting which metrics are defined in which layer with a clear rationale (dbt Semantic Layer for BI tool consumption, Snowflake semantic views for Cortex Analyst consumption).
5. THE Platform SHALL include at minimum 5 sample natural-language questions in documentation that demonstrate the "talk to your data" capability (e.g., "What was total revenue last quarter?", "Which customers have the highest energy consumption?").

---

### Requirement 19: Cortex Search for Unstructured Knowledge Retrieval

**User Story:** As a data engineer, I want a Cortex Search service configured over the knowledge base content, so that downstream applications can perform semantic search over manuals, procedures, and support articles.

#### Acceptance Criteria

1. THE Platform SHALL create a Cortex Search service on the `knowledge_chunks` table with the search column set to `chunk_text`.
2. THE Platform SHALL configure the Cortex Search service with filterable columns: `document_category`, `document_title`, enabling scoped searches (e.g., search only within "manual" category).
3. THE Platform SHALL provide a SQL-callable interface for querying the Cortex Search service, returning ranked results with chunk_text, document_title, document_category, and relevance score.
4. WHEN a search query is submitted, THE Cortex Search service SHALL return results within 5 seconds for queries against the full knowledge base corpus.
5. THE Platform SHALL include example search queries in documentation demonstrating retrieval of relevant manual sections for common support scenarios.

---

### Requirement 20: Streamlit in Snowflake — Lightweight Internal Application

**User Story:** As a data engineer, I want a lightweight Streamlit in Snowflake application that demonstrates platform consumption patterns, so that the portfolio showcases an end-to-end path from data product to internal application without building a full dashboard suite.

#### Acceptance Criteria

1. THE Platform SHALL implement one Streamlit in Snowflake application that combines at minimum two consumption patterns: a structured data query (e.g., customer or contract lookup from the dimensional model) and an unstructured search query (Cortex Search over the knowledge base).
2. THE Platform SHALL implement the Streamlit application as a Python file deployable to Snowflake's Streamlit runtime, stored in the repository under a `streamlit/` directory.
3. THE Platform SHALL ensure the Streamlit application queries only from the Marts_Layer and Semantic_Layer (public data product interfaces), not from staging or intermediate models.
4. THE Platform SHALL ensure the Streamlit application respects Snowflake role-based access control, running under the `LIGHTHOUSE_READER` role with access only to granted data products.
5. THE Platform SHALL include the Streamlit application source code, a README with deployment instructions, and example screenshots or descriptions of the expected UI in documentation.

---

### Requirement 21: Governance — Classification, Masking, and Row-Level Security

**User Story:** As a platform engineer, I want governance controls including data classification, dynamic masking, and row-level security implemented in Snowflake, so that the platform enforces data protection policies consistently across all data products.

#### Acceptance Criteria

1. THE Platform SHALL define Snowflake object tags for data classification: `LIGHTHOUSE.GOVERNANCE.CLASSIFICATION` with allowed values `PII`, `SENSITIVE`, `INTERNAL`, `PUBLIC`.
2. THE Platform SHALL apply classification tags to columns in the Marts_Layer containing personal data (customer name, email, phone, address) and sensitive data (invoice amounts, payment details).
3. THE Platform SHALL create dynamic data masking policies that mask PII columns (full mask for strings, null for dates) when queried by roles below `LIGHTHOUSE_ENGINEER`.
4. THE Platform SHALL create at minimum one row access policy that restricts data visibility by region or business unit, applied to the `fct_invoices` fact table as a demonstration.
5. THE Platform SHALL implement all governance objects (tags, masking policies, row access policies) as idempotent SQL scripts in the repository under a `snowflake/governance/` directory.
6. THE Platform SHALL document the governance model with a mapping of which policies apply to which tables and columns.

---

### Requirement 22: Governance — Data Quality, Testing Strategy, and Automated Monitoring

**User Story:** As a data engineer, I want a comprehensive dbt testing strategy covering schema tests, data quality tests, unit tests, and automated governance checks, so that the platform catches data issues before they reach data product consumers and enforces quality SLAs as code.

#### Acceptance Criteria

1. THE Platform SHALL implement dbt schema tests on all staging models: `not_null` on primary keys, `unique` on natural keys, `accepted_values` on status and type columns, and `relationships` tests for foreign key integrity.
2. THE Platform SHALL implement dbt data quality tests on marts models: row count anomaly detection (using dbt_utils or elementary), freshness validation, and business rule assertions (e.g., invoice amounts > 0, milestone dates in correct order).
3. THE Platform SHALL implement at minimum 3 dbt unit tests covering critical business logic transformations in the intermediate layer (e.g., customer entity matching logic, contract status derivation, energy usage daily aggregation).
4. THE Platform SHALL configure dbt test severity levels: `warn` for non-critical quality checks, `error` for data integrity violations that should block downstream model execution.
5. THE Platform SHALL generate a dbt docs site that includes test results, model lineage, and data product documentation accessible to platform consumers.
6. THE Platform SHALL implement dbt source freshness checks (`loaded_at_field` + `warn_after` / `error_after`) on every raw source, configured per source SLA: OLTP CDC (warn: 30 min, error: 60 min), CRM (warn: 90 min, error: 180 min), IoT (warn: 10 min, error: 30 min), Partner Feeds (warn: 36 hours, error: 72 hours).
7. THE Platform SHALL implement custom dbt generic tests (as reusable macros) for cross-model governance checks: referential integrity between facts and dimensions, surrogate key collision detection, and SCD2 validity window integrity (no overlapping valid_from/valid_to ranges for the same natural key).
8. THE Platform SHALL implement dbt tests on every data product public interface model that validate the model contract is not violated at runtime: column count, column names, data types, and not-null constraints on key columns.
9. THE Platform SHALL implement data volume anomaly tests on high-volume models (`fct_device_telemetry`, `fct_energy_usage_daily`) that warn when row counts deviate more than 30% from the trailing 7-day average, indicating potential ingestion failures or data spikes.
10. THE Platform SHALL implement PII governance tests as custom dbt tests that assert: all columns tagged as `PII` in model metadata have corresponding Snowflake masking policies applied, serving as an automated audit of masking coverage.
11. THE Platform SHALL configure dbt to store test results in a `TEST_RESULTS` schema (via elementary or custom on-run-end hooks) so that test pass/fail history is queryable in Snowflake for operational monitoring dashboards and alerting.
12. THE Platform SHALL include a Snowflake Task or scheduled query that reads from the test results history and triggers alerts (via email notification integration or webhook) when error-severity tests fail in production, closing the loop between dbt test execution and operational response.

---

### Requirement 23: CI/CD and Environment Strategy

**User Story:** As a platform engineer, I want a CI/CD pipeline configuration and environment strategy for the dbt project and Snowflake infrastructure, so that changes are validated, tested, and promoted through environments safely.

#### Acceptance Criteria

1. THE Platform SHALL define a dbt project structure with environment-specific target configurations for DEV, STAGING, and PROD, using dbt profiles with Snowflake database/schema overrides per environment.
2. THE Platform SHALL include a CI pipeline definition (GitHub Actions YAML) that on pull request: runs `dbt build --select state:modified+` against a CI-specific Snowflake database, executes all tests, and reports results.
3. THE Platform SHALL include a CD pipeline definition (GitHub Actions YAML) that on merge to main: runs `dbt build` against the PROD Snowflake database with full test execution.
4. THE Platform SHALL include a Snowflake infrastructure deployment script that can be executed per environment, applying database, warehouse, role, and governance changes idempotently.
5. THE Platform SHALL use dbt's `state:modified+` selection for CI builds to minimize build time and Snowflake compute cost during development iteration.
6. IF a dbt test fails during CI, THEN THE Platform SHALL block the pull request merge and report the failing test name, model, and error message in the CI output.

---

### Requirement 24: Cost, Performance, and Monitoring

**User Story:** As a platform engineer, I want cost controls, performance optimizations, and monitoring patterns implemented in the platform, so that the platform operates efficiently and issues are detected proactively.

#### Acceptance Criteria

1. THE Platform SHALL configure Snowflake resource monitors on each warehouse with credit quota alerts at 75% and 90% of monthly budget, and auto-suspend at 100%.
2. THE Platform SHALL configure Snowflake warehouse auto-suspend timers appropriate to workload pattern: 60 seconds for serving/query warehouses, 120 seconds for transformation warehouses.
3. THE Platform SHALL implement clustering keys on high-volume fact tables (`fct_energy_usage_daily`, `fct_device_telemetry`) on the date dimension key to optimize time-range query pruning.
4. THE Platform SHALL include a monitoring SQL script (or Snowflake Task) that queries `SNOWFLAKE.ACCOUNT_USAGE` views to report: daily credit consumption by warehouse, longest-running queries, failed task executions, and stale data product freshness.
5. THE Platform SHALL document performance considerations including: when to use clustering keys, warehouse sizing guidance per workload, and query optimization patterns for the dimensional model.

---

### Requirement 25: Tradeoff Analysis and Architecture Decision Records

**User Story:** As a senior data engineer, I want explicit tradeoff analyses documented for key architectural decisions, so that the portfolio demonstrates senior-level judgment and the rationale is transparent to reviewers.

#### Acceptance Criteria

1. THE Platform SHALL document a tradeoff analysis for Dynamic Tables vs Streams/Tasks vs dbt incrementals, with a recommendation for which pattern to use in which scenario within the Lighthouse platform (e.g., Dynamic Tables for near-real-time serving views, dbt incrementals for batch transformation, Streams/Tasks for event-driven micro-pipelines).
2. THE Platform SHALL document a tradeoff analysis for dbt Semantic Layer vs Snowflake semantic views, with a recommendation for a minimal-duplication strategy (dbt Semantic Layer for BI tool metrics, Snowflake semantic views for Cortex Analyst, shared physical mart layer).
3. THE Platform SHALL document a tradeoff analysis for managed ingestion (Fivetran/Airbyte/native connectors) vs custom ingestion code, with a recommendation per source type and explicit criteria for when custom code is justified.
4. THE Platform SHALL document a tradeoff analysis for single dbt project vs domain-oriented multi-project (mesh) architecture, with a recommendation for MVP (single project) and a migration path toward mesh as the platform scales.
5. THE Platform SHALL document a tradeoff analysis for portable dbt deployment (dbt Core / dbt Cloud) vs dbt Projects on Snowflake, with a recommendation based on the consultancy context (client flexibility, vendor lock-in, feature availability).
6. THE Platform SHALL format each tradeoff analysis as an Architecture Decision Record (ADR) with: context, options considered, decision, rationale, and consequences.

---

### Requirement 26: Repository Structure and Implementability

**User Story:** As a data engineer, I want the repository organized with a clear, standard structure containing all code, configuration, and documentation needed to deploy the platform, so that the project can be lifted and shifted to a real Snowflake account and dbt environment.

#### Acceptance Criteria

1. THE Platform SHALL organize the repository with the following top-level structure:
   - `dbt/` — dbt project (models, seeds, snapshots, macros, tests, semantic layer configs)
   - `snowflake/` — Snowflake SQL scripts (infrastructure, ingestion, governance, monitoring)
   - `streamlit/` — Streamlit application code
   - `docs/` — Architecture decision records, tradeoff analyses, architecture diagrams (as text/mermaid)
   - `seeds/` or `dbt/seeds/` — Sample/seed data files
   - `.github/workflows/` — CI/CD pipeline definitions
   - `README.md` — Project overview, setup instructions, architecture summary

2. THE Platform SHALL include a dbt project with a valid `dbt_project.yml`, `packages.yml` (referencing dbt_utils, dbt_date or similar), and `profiles.yml.example` with Snowflake connection template.
3. THE Platform SHALL include sample seed data (CSV files) for at minimum: `dim_date` generation inputs, product catalog reference data, and a small set of synthetic customer/contract/device records sufficient to demonstrate the full pipeline.
4. THE Platform SHALL include a `README.md` with: project overview, architecture summary (with Mermaid diagram), prerequisites (Snowflake account, dbt installation), setup instructions (step-by-step), and a guide to navigating the repository.
5. THE Platform SHALL ensure all dbt models compile and pass `dbt compile` without errors when pointed at a valid Snowflake target with the required raw schemas populated.
6. THE Platform SHALL ensure all Snowflake SQL scripts are syntactically valid and use `CREATE OR REPLACE` or `CREATE IF NOT EXISTS` patterns for idempotent execution.

---

### Requirement 27: Near-Real-Time Serving with Dynamic Tables

**User Story:** As a data engineer, I want to use Snowflake Dynamic Tables for specific near-real-time serving use cases, so that the platform demonstrates appropriate use of Snowflake-native capabilities alongside dbt-managed transformations.

#### Acceptance Criteria

1. THE Platform SHALL implement at minimum one Snowflake Dynamic Table for a near-real-time serving use case where dbt's batch scheduling is insufficient: a `device_latest_status` view that reflects the most recent telemetry event per device with a target lag of 5 minutes.
2. THE Platform SHALL define the Dynamic Table using a SQL script in the `snowflake/` directory, with explicit target_lag configuration and warehouse assignment.
3. THE Platform SHALL document why this specific use case uses a Dynamic Table instead of a dbt incremental model, referencing the tradeoff analysis in Requirement 25.
4. THE Platform SHALL ensure the Dynamic Table reads from the raw or staging layer (not duplicating dbt mart logic) and is exposed as a serving-layer object in a dedicated `SERVING` schema.
5. WHEN the source data changes, THE Dynamic Table SHALL refresh automatically within the configured target lag without manual intervention or external scheduling.

---

### Requirement 28: Data Mesh Readiness and Evolution Path

**User Story:** As a platform architect, I want the platform design to include a clear evolution path toward a data mesh operating model, so that the portfolio demonstrates awareness of organizational scaling patterns beyond a single monolithic platform.

#### Acceptance Criteria

1. THE Platform SHALL organize dbt models into domain-aligned groups (customer, billing, device, service) using dbt's group configuration, even within the single-project MVP structure.
2. THE Platform SHALL use dbt model access controls (`public`, `protected`, `private`) to enforce domain boundaries: only `public` models are accessible as cross-domain data product interfaces.
3. THE Platform SHALL document a migration path from the single dbt project to a multi-project mesh architecture, including: how to split by domain, how to use dbt Mesh (cross-project references), and what organizational prerequisites are needed.
4. THE Platform SHALL document how Snowflake data sharing (Secure Data Sharing or Snowflake Marketplace private listings) could distribute data products across organizational boundaries in a mesh model.
5. THE Platform SHALL include a conceptual diagram (Mermaid) showing the current single-project topology and the target mesh topology with domain ownership boundaries.

## Assumptions

1. **Cloud Provider**: The platform targets AWS as the primary cloud provider for object storage (S3) and network connectivity, but Snowflake SQL and dbt code are cloud-agnostic.
2. **Snowflake Edition**: The platform targets Snowflake Enterprise Edition trial account (30-day free trial). Enterprise Edition is required for dynamic data masking, row access policies, object tagging, and Cortex features. All features in the requirements are available on Enterprise trial except Openflow (managed connectors) and external network access.
3. **Trial Account Simulation Strategy**: Because Snowflake trial accounts do not support Openflow (managed CDC/SaaS connectors) or external network access, all ingestion is simulated using synthetic seed data loaded via internal stages and COPY INTO. The raw table schemas, metadata columns, and downstream models are designed production-correct so that swapping simulation for real connectors requires only changing the ingestion mechanism, not the transformation or serving layers.
4. **dbt Version**: The platform targets dbt Core 1.8+ or dbt Cloud with support for model contracts, model versions, model access, unit tests, and MetricFlow semantic layer.
5. **Cortex Feature Availability**: Cortex Analyst and Cortex Search are available on Enterprise trial accounts (subject to region availability and ~10 credits/day limit without payment method). The repository includes configuration and semantic model definitions; actual Cortex service creation requires a Snowflake account with these features enabled in the selected region.
6. **Synthetic Data**: All data in the repository is synthetic/fictional. No real company data is used. Seed data is designed to be realistic enough to demonstrate the full pipeline including CDC change history, incremental loads, streaming events, and SCD patterns.
7. **Single Consultant Team**: The MVP is designed to be implementable by a small senior consultant team (2-3 people) within a reasonable engagement timeline.
8. **No Real-Time Dashboard Requirement**: The platform enables analytics but does not include dashboard or visualization deliverables. Exposures document downstream consumers but do not implement them.
9. **Credit Budget Awareness**: The demo is designed to be runnable within the trial credit budget by using X-Small/Small warehouses with aggressive auto-suspend, minimal seed data volumes, and documented guidance on which features consume the most credits.
