# Governance Mapping — Policies, Tags, and Access Controls

## Classification Tags

| Table | Column | Classification |
|---|---|---|
| `customer_360` | `email` | PII |
| `customer_360` | `first_name` | PII |
| `customer_360` | `last_name` | PII |
| `customer_360` | `phone` | PII |
| `customer_360` | `address` | PII |
| `dim_customer` | `email` | PII |
| `dim_customer` | `first_name` | PII |
| `dim_customer` | `last_name` | PII |
| `dim_customer` | `phone` | PII |
| `dim_customer` | `address` | PII |
| `fct_invoices` | `amount` | SENSITIVE |
| `fct_payments` | `payment_amount` | SENSITIVE |

## Masking Policies

| Policy | Type | Behavior |
|---|---|---|
| `pii_string_mask` | STRING → STRING | `LIGHTHOUSE_ADMIN`/`ENGINEER`: full value; others: `***MASKED***` |
| `pii_date_mask` | DATE → DATE | `LIGHTHOUSE_ADMIN`/`ENGINEER`: full value; others: `NULL` |
| `pii_number_mask` | NUMBER → NUMBER | `LIGHTHOUSE_ADMIN`/`ENGINEER`: full value; others: `NULL` |
| `pii_timestamp_mask` | TIMESTAMP → TIMESTAMP | `LIGHTHOUSE_ADMIN`/`ENGINEER`: full value; others: `NULL` |

## Masking Policy Assignments

| Table | Column | Policy |
|---|---|---|
| `customer_360` | `email`, `first_name`, `last_name`, `phone`, `address` | `pii_string_mask` |
| `dim_customer` | `email`, `first_name`, `last_name`, `phone`, `address` | `pii_string_mask` |

## Row Access Policies

| Policy | Applied To | Logic |
|---|---|---|
| `region_row_access` | `fct_invoices` (pending region column) | `ADMIN`/`ENGINEER` see all; others filtered by session region |

## Role Hierarchy and Access

| Role | Sees PII? | Sees All Regions? | Purpose |
|---|---|---|---|
| `LIGHTHOUSE_ADMIN` | ✓ | ✓ | Full platform administration |
| `LIGHTHOUSE_ENGINEER` | ✓ | ✓ | Data engineering and development |
| `LIGHTHOUSE_TRANSFORMER` | ✗ (masked) | ✗ (filtered) | dbt transformation execution |
| `LIGHTHOUSE_READER` | ✗ (masked) | ✗ (filtered) | BI tools, Streamlit app, analysts |
