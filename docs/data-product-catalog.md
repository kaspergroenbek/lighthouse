# Lighthouse Data Product Catalog

## Overview

Lighthouse delivers six governed data products from five source systems. Each product is a set of marts-layer models with enforced contracts, public access, and versioning.

---

## 1. Customer 360

**Purpose**: Single unified customer profile merging OLTP, CRM, device, and service data.

| Model | Type | Description |
|-------|------|-------------|
| `dim_customer` | Dimension | Master customer record — demographics, region, segment, lifecycle status |
| `customer_360` | Data product | Wide denormalized view — customer + contracts + devices + service history |

**Key columns**: `customer_360_sk`, `customer_id`, `email`, `first_name`, `last_name`, `segment`, `region`, `total_contracts`, `active_contracts`, `active_device_count`, `lifetime_invoice_total`, `total_service_tickets`, `match_status`, `last_interaction_date`

**Sources joined**: `stg_oltp__customers` + `stg_crm__contacts` (via `int_customer__unified_profile`) + `stg_oltp__contracts` + `int_device__lifecycle` + `stg_oltp__invoices` + `int_service__ticket_enriched`

**Use cases**: Customer segmentation, churn prediction, personalized offers, support prioritization

---

## 2. Contract & Revenue

**Purpose**: Financial lifecycle — contracts, invoices, payments.

| Model | Type | Description |
|-------|------|-------------|
| `fct_invoices` | Fact | Invoice line items with amounts, dates, status |
| `fct_payments` | Fact | Payment transactions linked to invoices |
| `fct_contract_lifecycle` | Fact | Contract events — creation, renewal, cancellation, amendments |

**Key metrics**: MRR, ARPU, churn rate, payment aging

**Sources**: `stg_oltp__contracts`, `stg_oltp__invoices`, `stg_oltp__invoice_line_items`, `stg_oltp__payments` (via `int_billing__invoice_enriched`)

**Use cases**: Revenue reporting, billing analytics, contract renewal forecasting

---

## 3. Device & Usage

**Purpose**: IoT device fleet and energy consumption analytics.

| Model | Type | Description |
|-------|------|-------------|
| `dim_device` | Dimension | Device master — type, model, firmware, installation date, household |
| `fct_energy_usage_daily` | Fact | Daily aggregated energy readings per device |
| `fct_device_telemetry` | Fact | Raw telemetry events — temperature, status, alerts |
| `bridge_household_device` | Bridge | Many-to-many: households to devices |

**Key metrics**: Daily kWh, device uptime %, alert frequency, firmware currency

**Sources**: `stg_oltp__devices`, `stg_iot__energy_readings`, `stg_iot__device_status`, `stg_iot__temperature_readings`, `stg_iot__alert_events` (via `int_device__lifecycle`, `int_device__telemetry_daily`)

**Use cases**: Energy optimization, predictive maintenance, fleet management

---

## 4. Service Operations

**Purpose**: Service ticket lifecycle and support performance.

| Model | Type | Description |
|-------|------|-------------|
| `fct_service_ticket_lifecycle` | Fact | Ticket events — creation, assignment, escalation, resolution, closure |

**Key metrics**: MTTR, first-contact resolution rate, escalation rate, SLA compliance

**Sources**: `stg_crm__cases`, `stg_crm__case_comments` (via `int_service__ticket_enriched`, `int_customer__unified_profile`)

**Use cases**: Support team performance, SLA monitoring, service quality trends

---

## 5. Reference & Semantic

**Purpose**: Conformed dimensions and semantic interfaces shared across all products.

| Model | Type | Description |
|-------|------|-------------|
| `dim_date` | Dimension | Date spine from seed — fiscal periods, Danish holidays |
| `dim_time` | Dimension | Time-of-day dimension — 1440 minutes, business hour bands |
| `dim_geography` | Dimension | Nordic regions, postal codes, municipalities |
| `dim_product` | Dimension | Product/service catalog |
| `dim_household` | Dimension | Household addresses and types |
| `dim_contract` | Dimension | SCD2 contract dimension — type, status, dates, amounts |
| `bridge_household_device` | Bridge | Many-to-many: households to devices (also in Device & Usage) |

**Semantic interfaces**:
- dbt MetricFlow: Metrics inline on model YAML — for Looker, Tableau
- Snowflake Semantic Views: `ANALYTICS.SEMANTIC` schema — for Cortex Analyst

---

## 6. AI-Ready Knowledge

**Purpose**: Unstructured documents chunked and indexed for Cortex Search.

| Model | Type | Description |
|-------|------|-------------|
| `knowledge_chunks` | Data product | Document chunks with metadata and source tracking |

**Sources**: `stg_kb__documents`, `stg_kb__chunks`

**Use cases**: Cortex Search for support agents, RAG pipelines, knowledge retrieval

---

## Database Locations (PROD)

| Data Product | Database | Schema | Key Tables |
|-------------|----------|--------|------------|
| Customer 360 | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` | `dim_customer`, `customer_360` |
| Contract & Revenue | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` | `fct_invoices`, `fct_payments`, `fct_contract_lifecycle` |
| Device & Usage | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` | `dim_device`, `fct_energy_usage_daily`, `fct_device_telemetry` |
| Service Operations | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` | `fct_service_ticket_lifecycle` |
| Reference & Semantic | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` + `SEMANTIC` | `dim_date`, `dim_time`, `dim_geography`, `dim_product`, `dim_household`, `dim_contract`, `bridge_household_device`, semantic views |
| AI-Ready Knowledge | `LIGHTHOUSE_PROD_ANALYTICS` | `MARTS` | `knowledge_chunks` |
| Real-time serving | `LIGHTHOUSE_PROD_SERVING` | `REALTIME` | Dynamic Tables |
