# Lighthouse Streamlit Application

## Overview

A Streamlit in Snowflake application providing a focused customer and billing workflow for Version 1.

1. **Customer & Contract Lookup** - search customers by email or name
2. View current contracts from `dim_contract`
3. Review recent invoices from `fct_invoices`

## Deployment

1. In Snowflake, navigate to **Streamlit** under **Projects**
2. Create a new Streamlit app in the `LIGHTHOUSE_PROD_SERVING` database
3. Upload or sync `app.py` as the main application file
4. Set the warehouse to `SERVING_WH`
5. Run the app under a role with read access to the marts

## Permissions Required

- `LIGHTHOUSE_READER` role or equivalent read access to MARTS and SERVING schemas
- `SERVING_WH` warehouse usage

## Data Sources

| Screen | Tables Queried | Schema |
|---|---|---|
| Customer Lookup | `customer_360`, `dim_contract`, `fct_invoices`, `dim_customer` | `ANALYTICS.MARTS` |
