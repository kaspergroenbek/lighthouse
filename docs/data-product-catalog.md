# Lighthouse Data Product Catalog

## Overview

Lighthouse delivers curated business data products from five source systems.

This catalog focuses on Lighthouse-owned marts and data products.
Internal package-generated monitoring objects, such as Elementary observability models, are intentionally not treated as first-class business products here.

---

## 1. Customer 360

**Purpose**: Single unified customer profile merging OLTP, CRM, device, billing, and service history.

| Model | Type | Description |
|-------|------|-------------|
| `dim_customer` | Dimension | Customer dimension from SCD2 snapshot history |
| `customer_360` | Data product | Wide customer profile with contract, device, invoice, and service summaries |

**Key columns**: `customer_360_sk`, `customer_id`, `email`, `segment`, `region`, `total_contracts`, `active_contracts`, `active_device_count`, `lifetime_invoice_total`, `total_service_tickets`, `match_status`, `last_interaction_date`

**Sources joined**: `int_customer__unified_profile`, `stg_oltp__contracts`, `int_device__lifecycle`, `stg_oltp__invoices`, `bridge_service_ticket_customer`, `fct_service_ticket_lifecycle`

**Use cases**: segmentation, churn analysis, personalized offers, support prioritization

---

## 2. Contract and Revenue

**Purpose**: Financial lifecycle across contracts, invoices, and payments.

| Model | Type | Description |
|-------|------|-------------|
| `fct_invoices` | Fact | Invoice facts with amounts, dates, and status |
| `fct_payments` | Fact | Payment transactions linked to customers and contracts |
| `fct_contract_lifecycle` | Fact | Contract lifecycle events and states |

**Key metrics**: MRR, ARPU, churn rate, payment aging

**Sources**: `stg_oltp__contracts`, `stg_oltp__invoices`, `stg_oltp__invoice_line_items`, `stg_oltp__payments`, `int_billing__invoice_enriched`

**Use cases**: revenue reporting, billing analytics, renewal forecasting

---

## 3. Device and Usage

**Purpose**: IoT fleet and consumption analytics.

| Model | Type | Description |
|-------|------|-------------|
| `dim_device` | Dimension | Device master with type, model, firmware, and household |
| `fct_energy_usage_daily` | Fact | Daily energy usage at device-day grain |
| `fct_device_telemetry` | Fact | Telemetry event fact at event grain |
| `bridge_household_device` | Bridge | Household-to-device relationship |

**Key metrics**: daily kWh, alert frequency, fleet status, firmware currency

**Sources**: `stg_oltp__devices`, `stg_iot__energy_readings`, `stg_iot__device_status`, `stg_iot__temperature_readings`, `stg_iot__alert_events`, `int_device__lifecycle`, `int_device__telemetry_daily`

**Use cases**: fleet management, predictive maintenance, energy optimization

---

## 4. Service Operations

**Purpose**: Track ticket lifecycle while preserving Kimball grain discipline.

| Model | Type | Description |
|-------|------|-------------|
| `fct_service_ticket_lifecycle` | Fact | Ticket lifecycle fact at one row per service ticket |
| `bridge_service_ticket_customer` | Bridge | Ticket-to-customer attribution bridge for potentially many-to-many relationships |

**Key metrics**: MTTR, first-response time, escalation rate, SLA monitoring

**Sources**: `stg_crm__cases`, `stg_crm__case_comments`, `stg_crm__contacts`, `int_service__ticket_enriched`, `int_customer__unified_profile`, `dim_customer`

**Modeling note**: customer attribution is handled in the bridge, not forced directly into the ticket fact. This preserves ticket grain and makes relationship ambiguity explicit.

**Use cases**: support performance, service quality trends, ticket attribution analysis

---

## 5. Reference and Semantic

**Purpose**: Conformed dimensions and shared semantic interfaces.

| Model | Type | Description |
|-------|------|-------------|
| `dim_date` | Dimension | Calendar/date dimension |
| `dim_time` | Dimension | Time-of-day dimension |
| `dim_geography` | Dimension | Geography dimension |
| `dim_product` | Dimension | Product and service catalog |
| `dim_household` | Dimension | Household/site dimension |
| `dim_contract` | Dimension | Contract dimension |
| `bridge_household_device` | Bridge | Shared device relationship bridge |

**Semantic interfaces**:
- dbt docs and metadata contracts
- Snowflake semantic objects in the semantic schema

---

## 6. AI-Ready Knowledge

**Purpose**: Make unstructured support and product documents searchable and AI-ready.

| Model | Type | Description |
|-------|------|-------------|
| `knowledge_chunks` | Data product | Chunked documents with metadata and source tracking |

**Sources**: `stg_kb__documents`, `stg_kb__chunks`

**Use cases**: support search, Cortex Search, RAG-style retrieval

---

## Internal Observability Models

The dbt Cloud catalog will also show internal monitoring models from packages such as Elementary, including objects like:
- `alerts_*`
- `dbt_*`
- `data_monitoring_metrics`

These are useful operational assets, but they are not part of the curated Lighthouse business data-product layer.

---

## Database Locations (PROD)

| Data Product | Database | Schema | Key Tables |
|-------------|----------|--------|------------|
| Customer 360 | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` | `dim_customer`, `customer_360` |
| Contract and Revenue | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` | `fct_invoices`, `fct_payments`, `fct_contract_lifecycle` |
| Device and Usage | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` | `dim_device`, `fct_energy_usage_daily`, `fct_device_telemetry` |
| Service Operations | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` | `fct_service_ticket_lifecycle`, `bridge_service_ticket_customer` |
| Reference and Semantic | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` and Snowflake semantic schemas | `dim_date`, `dim_time`, `dim_geography`, `dim_product`, `dim_household`, `dim_contract`, `bridge_household_device` |
| AI-Ready Knowledge | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` | `knowledge_chunks` |
| Real-time serving | `LIGHTHOUSE_PROD_SERVING` | `REALTIME` | Dynamic Tables |
