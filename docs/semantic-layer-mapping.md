# Semantic Layer Mapping — dbt vs Snowflake

## Dual-Layer Strategy Rationale

Lighthouse uses two complementary semantic layers that share the same physical mart tables:

1. **dbt Semantic Layer (MetricFlow)** — for BI tool consumption (Tableau, Looker, Mode) via the dbt Semantic Layer API
2. **Snowflake Semantic Views** — for Cortex Analyst natural-language querying directly in Snowflake

This avoids metric duplication at the physical layer while serving two distinct consumption patterns.

## Metric Mapping

| Metric | dbt Semantic Layer | Snowflake Semantic View | Source Table |
|---|---|---|---|
| `total_revenue` | ✓ (SUM amount) | ✓ (SUM invoices.amount) | fct_invoices |
| `invoice_count` | ✓ (COUNT invoice_line_sk) | ✓ (COUNT invoices.invoice_line_sk) | fct_invoices |
| `average_daily_energy_consumption` | ✓ (AVG total_kwh) | — | fct_energy_usage_daily |
| `median_first_response_time` | ✓ (AVG time_to_first_response_hours) | — | fct_service_ticket_lifecycle |
| `active_customer_count` | ✓ (COUNT with filter) | — | customer_360 |
| `device_uptime_rate` | ✓ (derived) | — | customer_360 |
| `total_payments` | — | ✓ (SUM payments.payment_amount) | fct_payments |
| `average_invoice_amount` | — | ✓ (AVG invoices.amount) | fct_invoices |
| `late_payment_count` | — | ✓ (COUNT_IF late) | fct_payments |

## When to Use Which Layer

| Use Case | Recommended Layer |
|---|---|
| BI dashboards (Tableau, Looker) | dbt Semantic Layer |
| Ad-hoc natural-language queries | Snowflake Semantic View + Cortex Analyst |
| Programmatic metric access (APIs) | dbt Semantic Layer |
| Snowflake-native analytics (worksheets) | Snowflake Semantic View |
| Cross-domain metric exploration | dbt Semantic Layer (broader coverage) |

## Expansion Plan

As new domains are added to Cortex Analyst, create additional semantic views:
- `device_usage_analysis` — covering fct_energy_usage_daily, fct_device_telemetry, dim_device
- `service_operations_analysis` — covering fct_service_ticket_lifecycle, dim_customer


## Sample Cortex Analyst Questions

The following natural-language questions demonstrate the "talk to your data" capability using the `contract_revenue_analysis` semantic view:

1. **"What was total revenue by product category last quarter?"**
   → Cortex Analyst resolves `total_revenue` metric, slices by `products.category`, filters by `dates.quarter`

2. **"Show me the top 10 customers by revenue this year"**
   → Resolves `total_revenue`, groups by `customers.full_name`, filters `dates.year = 2025`, orders descending, limits 10

3. **"How many late payments were there in Q1 2025 by payment method?"**
   → Resolves `late_payment_count` metric, slices by `payments.payment_method`, filters quarter and year

4. **"What is the average invoice amount for commercial contracts?"**
   → Resolves `average_invoice_amount`, filters `contracts.contract_type = 'commercial_energy'`

5. **"Compare monthly revenue between residential and commercial segments for 2024"**
   → Resolves `total_revenue`, groups by `dates.month_name` and `customers.segment`, filters year
