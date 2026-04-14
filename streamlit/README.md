# Lighthouse Streamlit Application

## Overview

A Streamlit in Snowflake application providing two interfaces to the Lighthouse data platform:

1. **Customer & Contract Lookup** — search customers by email/name, view contracts and invoices from `customer_360`, `dim_contract`, `fct_invoices`
2. **Knowledge Base Search** — semantic search over product manuals and support articles via Cortex Search

## Deployment

1. In Snowflake, navigate to **Streamlit** under **Projects**
2. Create a new Streamlit app in the `LIGHTHOUSE_PROD_SERVING` database
3. Upload `app.py` as the main application file
4. Set the warehouse to `SERVING_WH`
5. Set the app to run under the `LIGHTHOUSE_READER` role

## Permissions Required

- `LIGHTHOUSE_READER` role (minimum) — read access to MARTS and SERVING schemas
- `SERVING_WH` warehouse usage
- Access to the Cortex Search service `knowledge_search_service`

## Data Sources

| Tab | Tables Queried | Schema |
|---|---|---|
| Customer Lookup | `customer_360`, `dim_contract`, `fct_invoices`, `dim_customer` | `ANALYTICS.MARTS` |
| Knowledge Search | `knowledge_search_service` (Cortex Search) | `ANALYTICS.MARTS` |
