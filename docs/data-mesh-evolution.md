# Data Mesh Evolution — Migration Path

## Current State: Single dbt Project

All four domains (customer, billing, device, service) live in one dbt project with domain-aligned groups and model access controls.

```mermaid
graph TB
    subgraph "Single dbt Project"
        STG[Staging Layer]
        INT[Intermediate Layer]
        subgraph "Marts Layer"
            CUST[Customer Domain]
            BILL[Billing Domain]
            DEV[Device Domain]
            SVC[Service Domain]
            CORE[Core/Shared Dimensions]
        end
    end
    STG --> INT --> CUST & BILL & DEV & SVC
    CORE --> CUST & BILL & DEV & SVC
```

## Target State: dbt Mesh (Multi-Project)

```mermaid
graph TB
    subgraph "Platform Project"
        P_STG[Staging Models]
        P_CORE[Core Dimensions]
    end
    subgraph "Customer Project"
        C_MART[customer_360, dim_customer]
    end
    subgraph "Billing Project"
        B_MART[fct_invoices, fct_payments]
    end
    subgraph "Device Project"
        D_MART[fct_energy_usage, fct_telemetry]
    end
    subgraph "Service Project"
        S_MART[fct_service_tickets]
    end
    P_STG --> C_MART & B_MART & D_MART & S_MART
    P_CORE --> C_MART & B_MART & D_MART & S_MART
```

## Migration Steps

1. Validate domain boundaries — ensure no `protected` model is referenced across groups
2. Extract Platform project — staging + core dimensions
3. Extract domain projects — one per domain with own `dbt_project.yml`
4. Configure cross-project references — `{{ ref('project_name', 'model_name') }}`
5. Set up per-project CI/CD
6. Configure Snowflake Secure Data Sharing for cross-account access if needed

## Organizational Prerequisites

- Each domain has a dedicated team or owner
- Clear data product contracts (already enforced via dbt model contracts)
- Shared understanding of conformed dimensions (Platform team owns)
- Per-domain CI/CD pipelines
