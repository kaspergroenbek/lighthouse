# dbt Model Conventions

## Naming Conventions

| Layer        | Pattern                          | Example                        |
|--------------|----------------------------------|--------------------------------|
| Staging      | `stg_{source}__{entity}`         | `stg_oltp__customers`          |
| Intermediate | `int_{domain}__{description}`    | `int_customer__unified_profile`|
| Marts dims   | `dim_{entity}`                   | `dim_customer`                 |
| Marts facts  | `fct_{business_process}`         | `fct_invoices`                 |
| Snapshots    | `snp_{entity}`                   | `snp_customers`                |
| Bridge       | `bridge_{entity1}_{entity2}`     | `bridge_household_device`      |
| Data product | descriptive name                 | `customer_360`                 |

## Layer Rules

### Staging (`models/staging/`)
- MUST only rename, cast, and deduplicate. No business logic.
- Organized by source: `oltp/`, `crm/`, `iot/`, `partner_feeds/`, `knowledge_base/`.

### Intermediate (`models/intermediate/`)
- MUST use `protected` access — never exposed as data products.
- Contains business logic and cross-source joins.
- Organized by domain: `customer/`, `billing/`, `device/`, `service/`.

### Marts (`models/marts/`)
- MUST use `public` access with enforced model contracts (column names, types, constraints).
- MUST use model versions starting at v1.
- Organized by domain: `core/`, `billing/`, `device/`, `service/`, `customer/`, `knowledge/`.

## dbt Features You MUST Use

- **Model contracts**: Enforced on all marts models.
- **Model groups**: Assign every model to one of: `customer`, `billing`, `device`, `service`.
- **Surrogate keys**: Always `dbt_utils.generate_surrogate_key()`.
- **MetricFlow semantic layer**: Define metrics inline on model YAML (dbt v1.12+ syntax).
- **Snapshots**: SCD Type 2 via timestamp strategy, placed in `snapshots/` directory.

## dbt Packages Available

- `dbt_utils` — surrogate keys, generic tests, utilities
- `dbt_date` — date dimension generation
- `elementary` — data observability, test result storage
