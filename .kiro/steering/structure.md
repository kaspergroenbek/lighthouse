# Project Structure

```
lighthouse/
├── dbt/                              # dbt transformation project
│   ├── dbt_project.yml
│   ├── packages.yml                  # dbt_utils, dbt_date, elementary
│   ├── profiles.yml.example          # Snowflake connection template
│   ├── models/
│   │   ├── staging/                  # Layer 1: source-conforming standardization
│   │   │   ├── oltp/                 # stg_oltp__{entity} — CDC source
│   │   │   ├── crm/                  # stg_crm__{entity} — SaaS source
│   │   │   ├── iot/                  # stg_iot__{entity} — streaming source
│   │   │   ├── partner_feeds/        # stg_partner__{entity} — batch files
│   │   │   └── knowledge_base/       # stg_kb__{entity} — unstructured docs
│   │   ├── intermediate/             # Layer 2: business logic, cross-source joins
│   │   │   ├── customer/             # int_customer__{description}
│   │   │   ├── billing/              # int_billing__{description}
│   │   │   ├── device/               # int_device__{description}
│   │   │   └── service/              # int_service__{description}
│   │   └── marts/                    # Layer 3: Kimball star schema
│   │       ├── core/                 # Conformed dimensions (dim_*)
│   │       ├── billing/              # fct_invoices, fct_payments, fct_contract_lifecycle
│   │       ├── device/               # fct_energy_usage_daily, fct_device_telemetry
│   │       ├── service/              # fct_service_ticket_lifecycle
│   │       ├── customer/             # customer_360
│   │       └── knowledge/            # knowledge_chunks
│   ├── snapshots/                    # SCD Type 2 snapshots (snp_{entity})
│   ├── seeds/                        # Static reference data CSVs
│   ├── macros/                       # Reusable SQL macros and custom generic tests
│   ├── tests/
│   │   ├── unit/                     # Unit tests for business logic
│   │   └── generic/                  # Custom generic tests (PII, volume anomaly)
│   └── semantic/                     # Legacy semantic YAML (pre-v1.12 only)
│
├── snowflake/                        # Snowflake SQL scripts
│   ├── infrastructure/               # Idempotent setup scripts (01-08 + deploy.sql)
│   ├── ingestion/                    # COPY INTO and seed loading scripts
│   ├── governance/                   # Tags, masking policies, row access policies
│   ├── semantic/                     # CREATE SEMANTIC VIEW scripts
│   └── monitoring/                   # Cost/performance monitoring queries
│
├── streamlit/                        # Streamlit in Snowflake app
│
├── data/                             # Synthetic seed data files
│   ├── oltp/                         # CDC simulation CSVs
│   ├── crm/                          # SaaS connector simulation CSVs
│   ├── iot_events/                   # JSON telemetry event files
│   ├── partner_feeds/                # CSV/Parquet partner files
│   └── knowledge_base/               # Markdown/text documents
│
├── docs/                             # Architecture Decision Records, diagrams
├── .github/workflows/                # CI/CD pipeline definitions
└── README.md
```

## Naming Conventions

| Layer        | Pattern                              | Example                          |
|--------------|--------------------------------------|----------------------------------|
| Staging      | `stg_{source}__{entity}`             | `stg_oltp__customers`            |
| Intermediate | `int_{domain}__{description}`        | `int_customer__unified_profile`  |
| Marts dims   | `dim_{entity}`                       | `dim_customer`                   |
| Marts facts  | `fct_{business_process}`             | `fct_invoices`                   |
| Snapshots    | `snp_{entity}`                       | `snp_customers`                  |
| Bridge       | `bridge_{entity1}_{entity2}`         | `bridge_household_device`        |
| Data product | descriptive name                     | `customer_360`                   |

## Snowflake Schema Layout

| Database                    | Schema            | Contents                              |
|-----------------------------|-------------------|---------------------------------------|
| `LIGHTHOUSE_{ENV}_RAW`      | `OLTP`            | CDC raw tables                        |
|                             | `CRM`             | SaaS connector raw tables             |
|                             | `IOT`             | Streaming telemetry raw tables        |
|                             | `PARTNER_FEEDS`   | Batch file raw tables                 |
|                             | `KNOWLEDGE_BASE`  | Document tracking, text, chunks       |
| `LIGHTHOUSE_{ENV}_ANALYTICS`| `STAGING`         | dbt staging models                    |
|                             | `INTERMEDIATE`    | dbt intermediate models               |
|                             | `MARTS`           | Dimensional model (dims + facts)      |
|                             | `SNAPSHOTS`       | dbt SCD2 snapshots                    |
|                             | `SEMANTIC`        | Semantic views for Cortex Analyst     |
|                             | `TEST_RESULTS`    | dbt test result history               |
| `LIGHTHOUSE_{ENV}_SERVING`  | `REALTIME`        | Dynamic Tables for near-real-time     |

## Key Architecture Rules

- Snowflake owns ingestion and infrastructure; dbt owns all transformation logic
- Staging models do no business logic — only rename, cast, deduplicate
- Intermediate models are `protected` access — never exposed as data products
- Marts models are `public` access with enforced model contracts
- All infrastructure SQL scripts must be idempotent (`CREATE OR REPLACE` / `CREATE IF NOT EXISTS`)
- Surrogate keys use `dbt_utils.generate_surrogate_key()` for deterministic hashing
- Domain groups: customer, billing, device, service
