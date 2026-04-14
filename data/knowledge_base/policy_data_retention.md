# NordHjem Energy — Data Retention Policy

## Document Information

- Policy ID: GOV-POL-001
- Version: 1.0
- Effective date: 2025-01-01
- Owner: NordHjem Data Governance Office
- Review cycle: Annual

## Purpose

This policy defines the retention periods for all data categories processed by NordHjem Energy's data platform. It ensures compliance with GDPR, Nordic energy sector regulations, and NordHjem's internal data governance standards.

## Scope

This policy applies to all data stored in the NordHjem Lighthouse data platform, including structured data (OLTP, CRM), semi-structured data (IoT telemetry), unstructured data (knowledge base documents), and derived analytical data (dimensional models, metrics).

## Retention Periods by Data Category

### Customer Personal Data

- Active customer records: Retained for the duration of the customer relationship plus 24 months
- Inactive customer records: Anonymized 24 months after last contract end date
- Customer communication history: 36 months from date of communication
- Customer consent records: Retained for 60 months after consent withdrawal

### Contract and Billing Data

- Active contracts: Retained for the duration of the contract
- Expired contracts: 60 months after contract end date (Danish Bookkeeping Act requirement)
- Invoices and payment records: 60 months from invoice date (tax compliance)
- Credit notes and adjustments: 60 months from issuance date

### Device and Telemetry Data

- Raw telemetry events: 13 months (rolling window)
- Daily aggregated telemetry: 60 months
- Device status history: 36 months after device decommission
- Alert event history: 24 months

### Service and Support Data

- Service tickets: 36 months after ticket closure
- Case comments and interaction logs: 36 months after associated ticket closure
- Customer satisfaction surveys: 24 months

### Knowledge Base Documents

- Product manuals: Retained until product end-of-life plus 24 months
- Service procedures: Retained until superseded plus 12 months
- Policy documents: Retained until superseded plus 60 months
- Support articles: Reviewed annually, archived after 24 months of no access

### Analytical and Derived Data

- Staging layer data: Mirrors source retention (no independent retention)
- Intermediate layer data: Ephemeral, rebuilt on each transformation run
- Dimensional model data: Follows the retention of the longest-lived source contributing to each record
- SCD Type 2 history: Retained for the full retention period of the underlying entity
- Metric aggregations: 60 months

## Data Deletion Process

When data reaches its retention limit:

1. Automated retention jobs identify records past their retention date
2. Records are flagged for deletion in a staging queue
3. A 30-day grace period allows for review before permanent deletion
4. Deletion is executed and logged in the data governance audit trail
5. Downstream derived data is refreshed to reflect the deletion

## Exceptions

Retention periods may be extended in the following cases:

- Active legal proceedings or regulatory investigations
- Customer dispute resolution in progress
- Explicit written request from the Data Protection Officer
- Regulatory audit notification

All exceptions must be documented and reviewed quarterly.

## Compliance

This policy is designed to comply with:

- EU General Data Protection Regulation (GDPR) Articles 5(1)(e) and 17
- Danish Bookkeeping Act (Bogforingsloven) Section 10
- Swedish Accounting Act (Bokforingslagen) Chapter 7
- Norwegian Accounting Act (Bokforingsloven) Section 13
