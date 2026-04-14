# dbt Testing Patterns

## Schema Tests (every model)

```yaml
columns:
  - name: {pk}_sk
    tests: [unique, not_null]
  - name: status
    tests:
      - accepted_values:
          values: ['active', 'inactive', 'cancelled']
  - name: customer_sk
    tests:
      - relationships:
          to: ref('dim_customer')
          field: customer_sk
```

## Source Freshness Thresholds

| Source | Warn | Error |
|--------|------|-------|
| OLTP CDC | 30 min | 60 min |
| CRM | 90 min | 180 min |
| IoT | 10 min | 30 min |
| Partner Feeds | 36 hours | 72 hours |

## Unit Tests (dbt v1.8+)

```yaml
unit_tests:
  - name: test_contract_status_derivation
    model: int_billing__contract_enriched
    given:
      - input: ref('stg_oltp__contracts')
        rows:
          - {contract_id: 1, status: 'active', end_date: '2025-12-31'}
    expect:
      rows:
        - {contract_id: 1, derived_status: 'active'}
```

## Custom Generic Tests (macros/)

- `test_referential_integrity` — fact FK values exist in dimension
- `test_surrogate_key_collision` — no hash collisions
- `test_scd2_no_overlap` — no overlapping validity windows
- `test_volume_anomaly` — row count within 30% of 7-day average
- `test_pii_masking_coverage` — PII columns have masking policies

## Rules

- Every staging model MUST have not_null on PK, unique on natural key
- Every mart model MUST have relationship tests for all FK columns
- At minimum 3 unit tests for critical intermediate business logic
- `error` severity for integrity violations, `warn` for quality checks
