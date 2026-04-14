½# Implementation Plan: Lighthouse — AI-Ready Data Product Platform on Snowflake + dbt

## Overview

This plan implements the Lighthouse platform in dependency order: Snowflake infrastructure first, then synthetic seed data and ingestion scripts, then dbt transformation layers bottom-up (staging → snapshots → intermediate → marts), then data products and semantic layer, then serving/AI features, then governance, CI/CD, monitoring, and documentation. Each task produces working, testable artifacts that build on previous steps.

## Tasks

- [x] 1. Snowflake infrastructure scripts
  - [x] 1.1 Create `snowflake/infrastructure/01_databases.sql` — idempotent script to create `LIGHTHOUSE_{ENV}_RAW`, `LIGHTHOUSE_{ENV}_ANALYTICS`, `LIGHTHOUSE_{ENV}_SERVING` databases using `CREATE DATABASE IF NOT EXISTS` with parameterized environment variable
    - _Requirements: 1.1, 1.3, 1.5_
  - [x] 1.2 Create `snowflake/infrastructure/02_warehouses.sql` — idempotent script to create `INGESTION_WH` (X-Small, 60s), `TRANSFORM_WH` (Small, 120s), `SERVING_WH` (Small, 60s), `AI_WH` (Medium, 120s) with `CREATE WAREHOUSE IF NOT EXISTS`
    - _Requirements: 1.2, 1.3_
  - [x] 1.3 Create `snowflake/infrastructure/03_roles.sql` — idempotent script to create role hierarchy `LIGHTHOUSE_ADMIN` → `LIGHTHOUSE_ENGINEER` → `LIGHTHOUSE_TRANSFORMER` → `LIGHTHOUSE_READER` with `GRANT ROLE` inheritance
    - _Requirements: 1.4, 1.3_
  - [x] 1.4 Create `snowflake/infrastructure/04_grants.sql` — idempotent script to grant database, schema, table, and warehouse privileges per role
    - _Requirements: 1.4, 1.3_
  - [x] 1.5 Create `snowflake/infrastructure/05_schemas.sql` — idempotent script to create all schemas: `RAW.OLTP`, `RAW.CRM`, `RAW.IOT`, `RAW.PARTNER_FEEDS`, `RAW.KNOWLEDGE_BASE`, `ANALYTICS.STAGING`, `ANALYTICS.INTERMEDIATE`, `ANALYTICS.MARTS`, `ANALYTICS.SNAPSHOTS`, `ANALYTICS.SEMANTIC`, `ANALYTICS.TEST_RESULTS`, `SERVING.REALTIME`
    - _Requirements: 1.1, 1.3_
  - [x] 1.6 Create `snowflake/infrastructure/06_stages.sql` — idempotent script to create internal stages per source (OLTP, CRM, IoT, Partner Feeds, Knowledge Base)
    - _Requirements: 1.3, 1.6_
  - [x] 1.7 Create `snowflake/infrastructure/07_integrations.sql` — idempotent script to create storage integrations (S3, documented) and API integrations for Cortex
    - _Requirements: 1.6, 1.7_
  - [x] 1.8 Create `snowflake/infrastructure/08_file_formats.sql` — idempotent script to create CSV, Parquet, and JSON file format objects per source
    - _Requirements: 1.3, 4.2_
  - [x] 1.9 Create `snowflake/infrastructure/deploy.sql` — orchestration script that calls scripts 01–08 in dependency order
    - _Requirements: 1.5_

- [x] 2. Checkpoint — Validate infrastructure scripts
  - Review all infrastructure SQL scripts for idempotency and correct naming conventions. Ensure all tests pass, ask the user if questions arise.

- [x] 3. Synthetic seed data generation
  - [x] 3.1 Create `data/oltp/` directory with synthetic CDC seed CSV files for all 11 OLTP entities (`customers`, `households`, `installations`, `devices`, `contracts`, `tariff_plans`, `products`, `services`, `invoices`, `invoice_line_items`, `payments`) — each file must include `_op`, `_source_ts`, `_connector_batch_id` columns with realistic INSERT/UPDATE/DELETE change history spanning 30+ days
    - _Requirements: 2.1, 2.2, 2.4, 2.6_
  - [x] 3.2 Create `data/crm/` directory with synthetic CRM seed CSV files for all 8 CRM objects (`accounts`, `contacts`, `cases`, `case_comments`, `opportunities`, `tasks`, `campaigns`, `campaign_members`) — each file must include `_loaded_at`, `_sync_id`, `_is_deleted` columns with multiple sync batches and soft-deleted records
    - _Requirements: 3.1, 3.2, 3.4, 3.6_
  - [x] 3.3 Create `data/iot_events/` directory with synthetic JSON telemetry event files covering `energy_reading`, `device_status`, `temperature_reading`, `alert_event` event types — include out-of-order and late-arriving events with realistic timestamps
    - _Requirements: 5.1, 5.2, 5.4, 5.5_
  - [x] 3.4 Create `data/partner_feeds/` directory with synthetic partner feed files: `grid_usage_readings` (CSV), `installation_certifications` (Parquet), `product_catalog_updates` (CSV)
    - _Requirements: 4.3, 4.4_
  - [x] 3.5 Create `data/knowledge_base/` directory with 7 synthetic Markdown/text documents: 2 product manuals, 2 service procedures, 1 policy document, 2 support articles
    - _Requirements: 6.2, 6.3_

- [x] 4. Ingestion SQL scripts
  - [x] 4.1 Create `snowflake/ingestion/load_oltp_seeds.sql` — raw table DDL for `RAW.OLTP` (all 11 entities with CDC metadata columns) + PUT/COPY INTO statements to load seed CSVs from internal stages
    - _Requirements: 2.1, 2.3, 2.6_
  - [x] 4.2 Create `snowflake/ingestion/load_crm_seeds.sql` — raw table DDL for `RAW.CRM` (all 8 objects with SaaS connector metadata columns) + PUT/COPY INTO statements
    - _Requirements: 3.1, 3.3, 3.6_
  - [x] 4.3 Create `snowflake/ingestion/load_iot_seeds.sql` — raw table DDL for `RAW.IOT.telemetry_events` (VARIANT column + extracted metadata + `_ingestion_date` partition column) + PUT/COPY INTO with JSON parsing
    - _Requirements: 5.1, 5.3, 5.7_
  - [x] 4.4 Create `snowflake/ingestion/load_partner_feeds.sql` — raw table DDL for `RAW.PARTNER_FEEDS` (3 entity tables with `_loaded_at`, `_source_file_name`, `_source_file_row_number` metadata) + PUT/COPY INTO + quarantine stage and `_file_load_errors` error logging table
    - _Requirements: 4.1, 4.2, 4.5, 4.6_
  - [x] 4.5 Create `snowflake/ingestion/load_knowledge_base.sql` — raw table DDL for `RAW.KNOWLEDGE_BASE` (`documents`, `document_text`, `document_chunks` tables) + PUT/COPY INTO for document loading and metadata registration
    - _Requirements: 6.1, 6.4, 6.5_
  - [x] 4.6 Create `snowflake/ingestion/chunk_documents.sql` — stored procedure to extract text and chunk documents (~512 tokens, 50-token overlap) with error logging for failed extractions
    - _Requirements: 6.5, 6.6, 6.7_

- [x] 5. Checkpoint — Validate seed data and ingestion scripts
  - Ensure all seed data files are well-formed and ingestion scripts reference correct stages, file formats, and table schemas. Ensure all tests pass, ask the user if questions arise.

- [x] 6. dbt project scaffolding
  - [x] 6.1 Create `dbt/dbt_project.yml` — project configuration with name, version, profile reference, model paths, snapshot paths, seed paths, macro paths, test paths, and model-level configurations (materializations, schema overrides per layer, domain groups for customer, billing, device, service)
    - _Requirements: 26.2, 28.1_
  - [x] 6.2 Create `dbt/packages.yml` — package dependencies: `dbt_utils`, `dbt_date`, `elementary`
    - _Requirements: 26.2_
  - [x] 6.3 Create `dbt/profiles.yml.example` — Snowflake connection template with environment-specific target configurations for DEV, STAGING, PROD
    - _Requirements: 23.1, 26.2_
  - [x] 6.4 Create `dbt/macros/generate_schema_name.sql` — custom macro to control schema naming per layer (STAGING, INTERMEDIATE, MARTS, SNAPSHOTS)
    - _Requirements: 26.2_

- [x] 7. dbt sources and seeds
  - [x] 7.1 Create dbt source YAML files for each raw schema (`RAW.OLTP`, `RAW.CRM`, `RAW.IOT`, `RAW.PARTNER_FEEDS`, `RAW.KNOWLEDGE_BASE`) with `loaded_at_field` and freshness thresholds (OLTP: warn 30m/error 60m, CRM: warn 90m/error 180m, IoT: warn 10m/error 30m, Partner: warn 36h/error 72h)
    - _Requirements: 7.4, 22.6_
  - [x] 7.2 Create `dbt/seeds/dim_date_seed.csv` — date dimension seed covering 2020–2030 with all required attributes (date_key, full_date, day_of_week, week_number_iso, month, quarter, year, is_weekend, is_danish_public_holiday, fiscal_year, fiscal_quarter)
    - _Requirements: 9.2, 15.2, 15.4_
  - [x] 7.3 Create `dbt/seeds/dim_time_seed.csv` — time dimension seed covering all 1440 minutes with time_key, hour, minute, time_of_day_band, is_business_hour
    - _Requirements: 9.2, 15.3, 15.4_

- [x] 8. dbt staging layer — OLTP and CRM sources
  - [x] 8.1 Create staging models for OLTP entities in `dbt/models/staging/oltp/`: `stg_oltp__customers`, `stg_oltp__households`, `stg_oltp__installations`, `stg_oltp__devices`, `stg_oltp__contracts`, `stg_oltp__tariff_plans`, `stg_oltp__products`, `stg_oltp__services`, `stg_oltp__invoices`, `stg_oltp__invoice_line_items`, `stg_oltp__payments` — each with CDC deduplication (latest record per natural key, filter DELETEs), column renaming to snake_case, type casting, and appropriate materialization (incremental for high-volume, view for reference)
    - _Requirements: 7.1, 7.2, 7.3, 7.6_
  - [x] 8.2 Create staging model YAML schema files for OLTP with not-null tests on PKs, unique tests on natural keys, and accepted_values tests on status columns
    - _Requirements: 7.5, 22.1_
  - [x] 8.3 Create staging models for CRM objects in `dbt/models/staging/crm/`: `stg_crm__accounts`, `stg_crm__contacts`, `stg_crm__cases`, `stg_crm__case_comments`, `stg_crm__opportunities`, `stg_crm__tasks`, `stg_crm__campaigns`, `stg_crm__campaign_members` — each filtering `_is_deleted = TRUE`, renaming, casting
    - _Requirements: 7.1, 7.2, 7.3_
  - [x] 8.4 Create staging model YAML schema files for CRM with not-null and unique tests
    - _Requirements: 7.5, 22.1_

- [x] 9. dbt staging layer — IoT, Partner Feeds, Knowledge Base sources
  - [x] 9.1 Create staging models for IoT in `dbt/models/staging/iot/`: `stg_iot__energy_readings`, `stg_iot__device_status`, `stg_iot__temperature_readings`, `stg_iot__alert_events` — extract from VARIANT column, deduplicate on `device_id + event_timestamp + event_type`, incremental materialization
    - _Requirements: 7.1, 7.2, 7.3, 7.6_
  - [x] 9.2 Create staging models for Partner Feeds in `dbt/models/staging/partner_feeds/`: `stg_partner__grid_usage`, `stg_partner__installation_certifications`, `stg_partner__product_catalog` — rename, cast, preserve file-level metadata
    - _Requirements: 7.1, 7.2_
  - [x] 9.3 Create staging models for Knowledge Base in `dbt/models/staging/knowledge_base/`: `stg_kb__documents`, `stg_kb__chunks` — standardize metadata columns
    - _Requirements: 7.1, 7.2_
  - [x] 9.4 Create staging model YAML schema files for IoT, Partner Feeds, and Knowledge Base with not-null, unique, and accepted_values tests
    - _Requirements: 7.5, 22.1_

- [x] 10. dbt snapshots for SCD Type 2
  - [x] 10.1 Create `dbt/snapshots/snp_customers.sql` — snapshot on `stg_oltp__customers` using timestamp strategy (`updated_at`), targeting `ANALYTICS.SNAPSHOTS` schema, tracking all attribute columns
    - _Requirements: 10.1, 10.2, 10.3, 10.4_
  - [x] 10.2 Create `dbt/snapshots/snp_contracts.sql` — snapshot on `stg_oltp__contracts` using timestamp strategy (`updated_at`), targeting `ANALYTICS.SNAPSHOTS` schema, tracking contract_type, status, tariff_plan_id, end_date
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [x] 11. Checkpoint — Validate staging layer and snapshots
  - Ensure all staging models compile, schema tests are defined, and snapshots target the correct schema. Ensure all tests pass, ask the user if questions arise.

- [x] 12. dbt intermediate layer
  - [x] 12.1 Create `dbt/models/intermediate/customer/int_customer__unified_profile.sql` — deterministic entity matching between OLTP customers and CRM contacts using shared natural keys (email, customer_id) with `match_status` flag for non-matches; materialized as `table`; access set to `protected`
    - _Requirements: 8.1, 8.2, 8.6_
  - [x] 12.2 Create `dbt/models/intermediate/billing/int_billing__invoice_enriched.sql` — join invoice line items with product, contract, and customer context; derive revenue classification; materialized as `view` or `ephemeral`
    - _Requirements: 8.1, 8.3, 8.5_
  - [x] 12.3 Create `dbt/models/intermediate/device/int_device__lifecycle.sql` — derive device lifecycle state (provisioned → active → degraded → decommissioned) from telemetry patterns and installation records
    - _Requirements: 8.1, 8.3, 8.4_
  - [x] 12.4 Create `dbt/models/intermediate/device/int_device__telemetry_daily.sql` — aggregate raw telemetry into daily device-level summaries (total_kwh, peak_kwh, avg_temperature, reading_count); materialized as `table`
    - _Requirements: 8.1, 8.3, 8.5_
  - [x] 12.5 Create `dbt/models/intermediate/service/int_service__ticket_enriched.sql` — map CRM case data to service ticket model with severity mapping and milestone extraction (opened_at, assigned_at, first_response_at, resolved_at, closed_at)
    - _Requirements: 8.1, 8.3_
  - [x] 12.6 Create intermediate layer YAML schema files with model descriptions, access set to `protected`, and appropriate tests
    - _Requirements: 8.6, 22.1_

- [x] 13. dbt unit tests for intermediate business logic
  - [x] 13.1 Create `dbt/tests/unit/test_customer_entity_matching.sql` — unit test validating deterministic matching logic in `int_customer__unified_profile` (match on email/customer_id, non-match handling)
    - _Requirements: 22.3_
  - [x] 13.2 Create `dbt/tests/unit/test_contract_status_derivation.sql` — unit test validating contract status state machine (created → activated → renewed/cancelled)
    - _Requirements: 22.3_
  - [x] 13.3 Create `dbt/tests/unit/test_energy_usage_daily_aggregation.sql` — unit test validating daily aggregation of telemetry readings (sum kWh, max peak, avg temp, count)
    - _Requirements: 22.3_

- [x] 14. Checkpoint — Validate intermediate layer and unit tests
  - Ensure all intermediate models compile, unit tests are defined, and access is set to `protected`. Ensure all tests pass, ask the user if questions arise.

- [ ] 15. dbt marts layer — conformed dimensions
  - [x] 15.1 Create `dbt/models/marts/core/dim_customer.sql` — SCD Type 2 dimension from `snp_customers` snapshot with `customer_sk` (surrogate via `dbt_utils.generate_surrogate_key`), `customer_id` (natural key), all attributes, `valid_from`, `valid_to`, `is_current`; model contract enforced; access `public`
    - _Requirements: 9.2, 9.6, 9.8, 9.9, 9.10_
  - [x] 15.2 Create `dbt/models/marts/core/dim_household.sql` — SCD Type 1 dimension with `household_sk`, `household_id`, address, postal_code, municipality, country; model contract enforced; access `public`
    - _Requirements: 9.2, 9.8, 9.9, 9.10_
  - [x] 15.3 Create `dbt/models/marts/core/dim_device.sql` — SCD Type 1 dimension with `device_sk`, device_serial, device_type, manufacturer, model, firmware_version, lifecycle_state; model contract enforced; access `public`
    - _Requirements: 9.2, 9.6, 9.8, 9.9, 9.10_
  - [x] 15.4 Create `dbt/models/marts/core/dim_product.sql` — SCD Type 1 dimension with `product_sk`, product_id, product_name, category, pricing_tier; model contract enforced; access `public`
    - _Requirements: 9.2, 9.6, 9.8, 9.9, 9.10_
  - [x] 15.5 Create `dbt/models/marts/core/dim_contract.sql` — SCD Type 2 dimension from `snp_contracts` snapshot with `contract_sk`, `contract_id`, contract_type, status, start_date, end_date, `valid_from`, `valid_to`, `is_current`; model contract enforced; access `public`
    - _Requirements: 9.2, 9.6, 9.8, 9.9, 9.10_
  - [x] 15.6 Create `dbt/models/marts/core/dim_date.sql` — static dimension from `dim_date_seed` with date_key, full_date, and all calendar attributes; model contract enforced; access `public`
    - _Requirements: 9.2, 15.2, 15.4, 15.5_
  - [x] 15.7 Create `dbt/models/marts/core/dim_time.sql` — static dimension from `dim_time_seed` with time_key, hour, minute, time_of_day_band, is_business_hour; model contract enforced; access `public`
    - _Requirements: 9.2, 15.3, 15.4, 15.5_
  - [x] 15.8 Create `dbt/models/marts/core/dim_geography.sql` — SCD Type 1 dimension with geography_sk, postal_code, municipality, region, country; model contract enforced; access `public`
    - _Requirements: 9.2, 15.1_
  - [x] 15.9 Create `dbt/models/marts/core/bridge_household_device.sql` — bridge table resolving many-to-many household-device assignments with household_sk, device_sk, effective_from, effective_to
    - _Requirements: 9.7_
  - [x] 15.10 Create YAML schema files for all core dimension models with column descriptions, grain statements, model contracts, not-null/unique tests on keys, and relationships tests
    - _Requirements: 9.9, 9.10, 22.1, 22.8_

- [x] 16. dbt marts layer — fact tables
  - [x] 16.1 Create `dbt/models/marts/billing/fct_invoices.sql` — transaction fact at invoice line item grain with FKs to dim_customer, dim_household, dim_product, dim_contract, dim_date; additive measures: amount, quantity, tax_amount, net_amount; model contract enforced; access `public`
    - _Requirements: 9.1, 9.3, 9.8, 9.9, 9.10_
  - [x] 16.2 Create `dbt/models/marts/billing/fct_payments.sql` — transaction fact at payment grain with FKs to dim_customer, dim_household, dim_contract, dim_date; measures: payment_amount, is_late_payment; model contract enforced; access `public`
    - _Requirements: 9.1, 9.9, 9.10_
  - [x] 16.3 Create `dbt/models/marts/billing/fct_contract_lifecycle.sql` — accumulating snapshot at contract version grain with milestone dates (created_at, activated_at, renewed_at, cancelled_at) and duration measures; FKs to dim_customer, dim_household, dim_product, dim_contract, dim_date; model contract enforced; access `public`
    - _Requirements: 9.1, 12.1, 12.2_
  - [x] 16.4 Create `dbt/models/marts/device/fct_energy_usage_daily.sql` — periodic snapshot at device-day grain with FKs to dim_device, dim_household, dim_customer, dim_product, dim_date, dim_time; measures: total_kwh, peak_kwh, avg_temperature, reading_count; model contract enforced; access `public`; clustering key on date_key
    - _Requirements: 9.1, 9.4, 9.9, 9.10, 24.3_
  - [x] 16.5 Create `dbt/models/marts/device/fct_device_telemetry.sql` — transaction fact at telemetry event grain with FKs to dim_device, dim_household, dim_date, dim_time; measures: reading_value, event_type; model contract enforced; access `public`; clustering key on date_key
    - _Requirements: 9.1, 13.1, 13.2, 24.3_
  - [x] 16.6 Create `dbt/models/marts/service/fct_service_ticket_lifecycle.sql` — accumulating snapshot at service ticket grain with milestone dates (opened_at, assigned_at, first_response_at, resolved_at, closed_at) and duration measures; FKs to dim_customer, dim_household, dim_device, dim_contract, dim_date; model contract enforced; access `public`
    - _Requirements: 9.1, 9.5, 14.1, 14.2_
  - [x] 16.7 Create YAML schema files for all fact models with column descriptions, grain statements, model contracts, relationships tests (FK → dim), accepted_values tests, accepted_range tests (energy 0–9999 kWh), milestone date ordering tests, and volume anomaly tests
    - _Requirements: 9.9, 9.10, 13.5, 14.4, 22.1, 22.2, 22.9_

- [x] 17. Checkpoint — Validate marts layer
  - Ensure all dimension and fact models compile, model contracts are enforced, relationships tests pass, and the enterprise bus matrix is fully covered. Ensure all tests pass, ask the user if questions arise.

- [x] 18. dbt data products — Customer 360 and Knowledge Chunks
  - [x] 18.1 Create `dbt/models/marts/customer/customer_360.sql` — one row per customer combining OLTP demographics, CRM interaction summary, and derived metrics (total_contracts, active_device_count, lifetime_invoice_total, avg_satisfaction_score, total_service_tickets, last_interaction_date); model contract enforced; access `public`
    - _Requirements: 11.1, 11.3, 11.6_
  - [x] 18.2 Create YAML schema file for `customer_360` with column descriptions, PII classification annotations on name/email/phone/address columns, grain statement, freshness SLA documentation, and dbt exposure for downstream consumers
    - _Requirements: 11.4, 11.6_
  - [x] 18.3 Create `dbt/models/marts/knowledge/knowledge_chunks.sql` — one row per document chunk with chunk_id, document_id, chunk_sequence_number, chunk_text, document_title, document_category, source_file_name, _loaded_at; model contract enforced; access `public`
    - _Requirements: 16.1, 16.2_
  - [x] 18.4 Create YAML schema file for `knowledge_chunks` with referential integrity test to document tracking table and dbt exposure documenting "Support Agent Copilot" consumer
    - _Requirements: 16.2, 16.5_

- [x] 19. Custom dbt generic tests and macros
  - [x] 19.1 Create `dbt/macros/test_referential_integrity.sql` — reusable generic test macro validating all FK values in a fact table exist in the referenced dimension table
    - _Requirements: 22.7_
  - [x] 19.2 Create `dbt/macros/test_surrogate_key_collision.sql` — reusable generic test macro detecting hash collisions in surrogate keys
    - _Requirements: 22.7_
  - [x] 19.3 Create `dbt/macros/test_scd2_no_overlap.sql` — reusable generic test macro validating no overlapping valid_from/valid_to ranges for the same natural key in SCD2 dimensions
    - _Requirements: 22.7_
  - [x] 19.4 Create `dbt/tests/generic/test_pii_masking_coverage.sql` — custom test asserting all PII-tagged columns have corresponding Snowflake masking policies applied
    - _Requirements: 22.10_
  - [x] 19.5 Create `dbt/tests/generic/test_volume_anomaly.sql` — custom test warning when row counts deviate >30% from trailing 7-day average on high-volume models
    - _Requirements: 22.9_
  - [x] 19.6 Apply custom generic tests to mart models: referential integrity on all fact tables, surrogate key collision on all dimensions, SCD2 no-overlap on dim_customer and dim_contract
    - _Requirements: 22.7, 22.8_

- [x] 20. dbt Semantic Layer — MetricFlow definitions
  - [x] 20.1 Add inline MetricFlow semantic model and metric definitions to `fct_invoices` YAML — entities (invoice_line primary, customer/household/product/contract/date foreign), measures (amount, quantity, tax_amount), metrics (total_revenue as SUM amount, invoice_count as COUNT)
    - _Requirements: 17.1, 17.2, 17.4, 17.5_
  - [x] 20.2 Add inline MetricFlow semantic model and metric definitions to `fct_energy_usage_daily` YAML — entities, measures (total_kwh, peak_kwh, avg_temperature), metrics (average_daily_energy_consumption as AVG total_kwh)
    - _Requirements: 17.1, 17.2, 17.4, 17.5_
  - [x] 20.3 Add inline MetricFlow semantic model and metric definitions to `fct_service_ticket_lifecycle` YAML — entities, measures (time_to_first_response, time_to_resolve), metrics (median_first_response_time)
    - _Requirements: 17.1, 17.2, 17.4, 17.5_
  - [x] 20.4 Add inline MetricFlow semantic model definitions to `dim_customer` and `dim_date` YAML — entities, dimensions for slicing (segment, region, date hierarchy)
    - _Requirements: 17.1, 17.3, 17.4_
  - [x] 20.5 Define derived metrics: `active_customer_count` (count_distinct customers with active contracts), `device_uptime_rate` (percentage of online devices)
    - _Requirements: 17.2_

- [x] 21. dbt exposures and model versioning
  - [x] 21.1 Create dbt exposures documenting downstream consumers: "Revenue Reporting Dashboard" (consuming fct_invoices, fct_payments), "Contract Renewal Prediction Model" (consuming fct_contract_lifecycle), "Device Health Anomaly Detection Model" (consuming fct_device_telemetry), "Service SLA Compliance Monitoring" (consuming fct_service_ticket_lifecycle), "Support Agent Copilot" (consuming knowledge_chunks)
    - _Requirements: 12.5, 13.6, 14.5, 16.5_
  - [x] 21.2 Add model versioning (v1) to all public-facing mart models (dimensions, facts, customer_360, knowledge_chunks) in their YAML schema files
    - _Requirements: 12.4, 9.10_

- [x] 22. Checkpoint — Validate data products and semantic layer
  - Ensure all data product models compile, model contracts are enforced, semantic layer definitions are valid, exposures reference correct models, and custom tests are applied. Ensure all tests pass, ask the user if questions arise.

- [x] 23. Snowflake semantic view for Cortex Analyst
  - [x] 23.1 Create `snowflake/semantic/contract_revenue_semantic.sql` — `CREATE OR REPLACE SEMANTIC VIEW` for Contract and Revenue domain covering fct_invoices, fct_payments, dim_customer, dim_contract, dim_product, dim_date with TABLES, RELATIONSHIPS, FACTS, DIMENSIONS (with SYNONYMS and COMMENT), and METRICS definitions
    - _Requirements: 18.1, 18.2, 18.3_
  - [x] 23.2 Create `docs/semantic-layer-mapping.md` — document mapping which metrics exist in dbt Semantic Layer vs Snowflake semantic views, with rationale for the dual-layer strategy
    - _Requirements: 18.4_
  - [x] 23.3 Add 5 sample natural-language questions to documentation demonstrating Cortex Analyst "talk to your data" capability
    - _Requirements: 18.5_

- [x] 24. Cortex Search service
  - [x] 24.1 Create `snowflake/cortex/cortex_search_service.sql` — `CREATE OR REPLACE CORTEX SEARCH SERVICE` on knowledge_chunks.chunk_text with filterable attributes document_category and document_title, using AI_WH, target lag 24 hours
    - _Requirements: 19.1, 19.2, 16.3, 16.4_
  - [x] 24.2 Add example search queries to documentation demonstrating retrieval of relevant manual sections for common support scenarios
    - _Requirements: 19.5_

- [x] 25. Dynamic Table for near-real-time serving
  - [x] 25.1 Create `snowflake/serving/device_latest_status.sql` — `CREATE OR REPLACE DYNAMIC TABLE` in `SERVING.REALTIME` schema showing latest telemetry event per device with 5-minute target lag, using SERVING_WH
    - _Requirements: 27.1, 27.2, 27.4_

- [x] 26. Streamlit in Snowflake application
  - [x] 26.1 Create `streamlit/app.py` — Streamlit application with two tabs: (1) structured data query for customer/contract lookup from customer_360, dim_contract, fct_invoices; (2) unstructured search via Cortex Search over knowledge base; running under LIGHTHOUSE_READER role, querying only from MARTS and SERVING schemas
    - _Requirements: 20.1, 20.2, 20.3, 20.4_
  - [x] 26.2 Create `streamlit/README.md` — deployment instructions for Streamlit in Snowflake, expected UI description, and role/permission requirements
    - _Requirements: 20.5_

- [x] 27. Checkpoint — Validate serving and AI layer
  - Ensure semantic view SQL is valid, Cortex Search service definition is correct, Dynamic Table uses CREATE OR REPLACE, and Streamlit app queries only public interfaces. Ensure all tests pass, ask the user if questions arise.

- [x] 28. Governance objects — classification, masking, row-level security
  - [x] 28.1 Create `snowflake/governance/tags.sql` — `CREATE TAG IF NOT EXISTS` for `LIGHTHOUSE.GOVERNANCE.CLASSIFICATION` with allowed values PII, SENSITIVE, INTERNAL, PUBLIC
    - _Requirements: 21.1_
  - [x] 28.2 Create `snowflake/governance/masking_policies.sql` — `CREATE OR REPLACE MASKING POLICY` for PII strings (full mask), dates (null), and numbers (null) based on current role check against LIGHTHOUSE_ENGINEER and LIGHTHOUSE_ADMIN
    - _Requirements: 21.3, 11.5_
  - [x] 28.3 Create `snowflake/governance/row_access_policies.sql` — `CREATE OR REPLACE ROW ACCESS POLICY` for region-based access restriction on fct_invoices
    - _Requirements: 21.4, 12.6_
  - [x] 28.4 Create `snowflake/governance/apply_policies.sql` — idempotent script to apply classification tags to PII/SENSITIVE columns in marts, apply masking policies to PII columns, and apply row access policy to fct_invoices
    - _Requirements: 21.2, 21.5_
  - [x] 28.5 Create `docs/governance-mapping.md` — document mapping which policies apply to which tables and columns
    - _Requirements: 21.6_

- [x] 29. dbt test results monitoring and alerting
  - [x] 29.1 Configure dbt to store test results in `ANALYTICS.TEST_RESULTS` schema via elementary package or custom `on-run-end` hook in `dbt/dbt_project.yml`
    - _Requirements: 22.11_
  - [x] 29.2 Create `snowflake/monitoring/test_alert_task.sql` — Snowflake Task that reads test results history and triggers alerts when error-severity tests fail in production
    - _Requirements: 22.12_

- [x] 30. CI/CD pipeline definitions
  - [x] 30.1 Create `.github/workflows/ci.yml` — GitHub Actions workflow triggered on PR to main: checkout, install dbt, `dbt deps`, `dbt build --select state:modified+ --defer --state prod-manifest/`, `dbt test --select state:modified+`, report results, block merge on test failure
    - _Requirements: 23.2, 23.5, 23.6_
  - [x] 30.2 Create `.github/workflows/cd.yml` — GitHub Actions workflow triggered on merge to main: checkout, install dbt, `dbt deps`, `dbt build --target prod`, `dbt test --target prod`, upload manifest artifact for state comparison
    - _Requirements: 23.3_

- [x] 31. Cost monitoring and resource controls
  - [x] 31.1 Create `snowflake/monitoring/resource_monitors.sql` — `CREATE OR REPLACE RESOURCE MONITOR` per warehouse with credit quota alerts at 75%, 90%, and auto-suspend at 100%
    - _Requirements: 24.1_
  - [x] 31.2 Create `snowflake/monitoring/monitoring_queries.sql` — SQL queries against `SNOWFLAKE.ACCOUNT_USAGE` views reporting daily credit consumption by warehouse, longest-running queries, failed task executions, and stale data product freshness
    - _Requirements: 24.4_

- [x] 32. Checkpoint — Validate governance, CI/CD, and monitoring
  - Ensure all governance SQL scripts are idempotent, CI/CD workflows are syntactically valid YAML, resource monitors are configured, and test alerting is wired. Ensure all tests pass, ask the user if questions arise.

- [x] 33. Documentation — ingestion architecture docs
  - [x] 33.1 Add production ingestion architecture documentation to each ingestion script or a dedicated `docs/ingestion-architecture.md` covering: CDC production path (managed connector, 15-min latency, resume-from-offset), CRM production path (managed SaaS connector, 60-min sync, daily reconciliation), batch production path (external stages on S3, Snowpipe auto-ingest, archive patterns), streaming production path (Snowpipe Streaming API or Kafka, 5-min latency, backpressure), unstructured production path (PARSE_DOCUMENT for PDFs)
    - _Requirements: 2.5, 3.5, 4.7, 5.6, 6.3_

- [x] 34. Documentation — Architecture Decision Records
  - [x] 34.1 Create `docs/adr/001-dynamic-tables-vs-streams-tasks-vs-dbt-incrementals.md` — ADR with context, options, decision, rationale, consequences for when to use Dynamic Tables vs Streams/Tasks vs dbt incrementals
    - _Requirements: 25.1, 27.3_
  - [x] 34.2 Create `docs/adr/002-dbt-semantic-layer-vs-snowflake-semantic-views.md` — ADR for dual semantic layer strategy with minimal-duplication rationale
    - _Requirements: 25.2_
  - [x] 34.3 Create `docs/adr/003-managed-vs-custom-ingestion.md` — ADR for managed ingestion vs custom code per source type
    - _Requirements: 25.3_
  - [x] 34.4 Create `docs/adr/004-single-vs-multi-project-dbt.md` — ADR for single project MVP with mesh migration path
    - _Requirements: 25.4_
  - [x] 34.5 Create `docs/adr/005-dbt-core-vs-dbt-cloud-vs-snowflake-native.md` — ADR for dbt deployment strategy in consultancy context
    - _Requirements: 25.5_

- [x] 35. Documentation — Data mesh evolution and README
  - [x] 35.1 Create `docs/data-mesh-evolution.md` — migration path from single dbt project to multi-project mesh, including domain splitting strategy, dbt Mesh cross-project references, Snowflake Secure Data Sharing, organizational prerequisites, and Mermaid diagram showing current vs target topology
    - _Requirements: 28.3, 28.4, 28.5_
  - [x] 35.2 Create `README.md` — project overview, architecture summary with Mermaid diagram, prerequisites (Snowflake account, dbt installation), step-by-step setup instructions, repository navigation guide, and performance considerations (clustering keys, warehouse sizing, query optimization)
    - _Requirements: 26.4, 24.5_

- [x] 36. Final checkpoint — Full platform validation
  - Ensure all files are created, all dbt models compile, all tests are defined, all SQL scripts are idempotent, CI/CD workflows are valid, documentation is complete, and the repository structure matches the design. Ensure all tests pass, ask the user if questions arise.

## Notes

- All tasks produce code artifacts (SQL, YAML, Python, Markdown) — no manual testing or deployment tasks are included
- Each task references specific requirements for traceability across all 28 requirements
- Checkpoints at tasks 2, 5, 11, 14, 17, 22, 27, 32, and 36 ensure incremental validation
- The design explicitly states property-based testing does not apply to this platform (infrastructure-as-code, declarative transformations, external service integration) — testing is handled through dbt's native testing framework
- Implementation languages: SQL (Snowflake + dbt Jinja-SQL), Python (Streamlit), YAML (dbt configs, CI/CD, semantic layer)
- All Snowflake DDL scripts use `CREATE OR REPLACE` or `CREATE IF NOT EXISTS` for idempotent execution
