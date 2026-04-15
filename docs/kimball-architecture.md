# Kimball Architecture Walkthrough

This document describes the Lighthouse warehouse in Kimball terms and records the modeling choices we are making for the Snowflake + dbt Cloud version of the project.

## Core Kimball Principles Applied

1. Declare the grain first.
2. Separate source cleanup from dimensional presentation.
3. Conform dimensions before building facts.
4. Keep fact tables faithful to their declared grain.
5. Use bridge tables when business relationships are genuinely many-to-many.
6. Treat tests as grain enforcement, not just technical validation.

## How the Repo Maps to Kimball

### Source-aligned staging

`dbt/models/staging/` is the source-conformance layer.

Purpose:
- filter deleted records
- deduplicate replicated source rows
- standardize types and names
- preserve source business keys

This is not the dimensional layer. It is the landing zone for clean source-shaped tables.

### Integration and harmonization

`dbt/models/intermediate/` is the enterprise integration layer.

Purpose:
- reconcile source systems
- apply entity matching
- enrich event records
- create reusable, business-meaningful intermediate tables

This is where cross-system logic belongs, but it should still avoid hiding dimensional ambiguity.

### Dimensional marts

`dbt/models/marts/` is the Kimball presentation layer.

Purpose:
- conformed dimensions
- fact tables at explicit grain
- bridge tables when relationships are many-to-many
- business-facing star schema for BI, semantic layers, and apps

## Current Warehouse Grain Decisions

### Dimensions

- `dim_customer`: one row per customer version from the SCD2 snapshot
- `dim_contract`: one row per contract version
- `dim_device`: one row per device
- `dim_household`: one row per household
- `dim_product`: one row per product
- `dim_date`: one row per calendar day
- `dim_time`: one row per time grain in the seed

### Facts

- `fct_invoices`: one row per invoice
- `fct_payments`: one row per payment
- `fct_contract_lifecycle`: one row per contract lifecycle event/state at the modeled grain
- `fct_energy_usage_daily`: one row per device-household-customer-day usage grain as defined in the model
- `fct_device_telemetry`: one row per telemetry event grain as defined in the model
- `fct_service_ticket_lifecycle`: one row per service ticket

### Bridge tables

- `bridge_service_ticket_customer`: one row per service ticket and customer pair

## Why Service Tickets Needed a Kimball Correction

The original service fact attempted to attach `customer_sk` directly to `fct_service_ticket_lifecycle` by joining tickets to the customer-unification logic through `crm_contact_id`.

That approach violated Kimball discipline because:
- the fact declared a ticket grain
- the customer relationship was not guaranteed to be one-to-one
- a dimensional join could therefore duplicate tickets
- the uniqueness test on `service_ticket_sk` correctly exposed the grain violation

Kimball would treat this as a modeling decision, not a test nuisance.

## The Kimball-Correct Pattern We Adopted

We split the service mart into:

1. `fct_service_ticket_lifecycle`
- pure ticket-grain fact
- no ambiguous customer foreign key
- one row per ticket

2. `bridge_service_ticket_customer`
- resolves ticket-to-customer attribution separately
- supports legitimate many-to-many relationships
- stores one row per ticket-customer pair
- includes `allocation_pct` for future weighted allocation logic

This keeps the fact table honest while still preserving the customer relationship for downstream analysis.

## Customer 360 Under Kimball Principles

`customer_360` is a denormalized data product, not a core conformed dimension.

That means:
- it can aggregate from multiple stars
- it should consume the bridge for service-ticket attribution
- it should count distinct tickets per customer rather than relying on a forced one-to-one customer assignment in the service fact

## Rationalization of the Matching Logic

`int_customer__unified_profile` still performs deterministic customer-contact matching.

That is acceptable in Kimball terms if it is treated as conformance logic and documented as such.

The important distinction is:
- one row per customer in the unified profile is acceptable
- forcing that same logic into a ticket-grain fact is not acceptable when the relationship is ambiguous

## What This Means for dbt

This repo uses dbt in a Kimball-friendly way:
- staging models clean replicated sources
- intermediate models harmonize cross-system entities
- marts define star-schema presentation objects
- tests enforce grain and referential integrity

In dbt terms, the failing uniqueness tests were doing exactly what we want: they surfaced a mismatch between declared grain and actual join behavior.

## Practical Modeling Rules Going Forward

1. If a fact says "one row per X", every join into that fact must preserve one row per X.
2. If a relationship can multiply rows and that is business-valid, model a bridge.
3. If a relationship multiplies rows because of source noise, fix it in staging or intermediate before marts.
4. Do not hide many-to-many business relationships inside a dimension foreign key.
5. Keep denormalized data products like `customer_360` downstream of the dimensional truth, not in place of it.

## Files That Embody the Kimball Service Pattern

- `dbt/models/staging/crm/stg_crm__cases.sql`
- `dbt/models/staging/crm/stg_crm__contacts.sql`
- `dbt/models/staging/crm/stg_crm__accounts.sql`
- `dbt/models/intermediate/customer/int_customer__unified_profile.sql`
- `dbt/models/marts/service/fct_service_ticket_lifecycle.sql`
- `dbt/models/marts/service/bridge_service_ticket_customer.sql`
- `dbt/models/marts/customer/customer_360.sql`

## Suggested Next Evolution

If the business later clarifies that a service ticket belongs to exactly one contractual customer, we can replace the bridge-based attribution with a stronger single-customer rule. Until then, the bridge pattern is the safer Kimball design.
