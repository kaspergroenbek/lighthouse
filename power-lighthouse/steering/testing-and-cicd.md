# Testing & CI/CD

## Testing Strategy

- **Unit tests**: Validate intermediate layer business logic. Located in `dbt/tests/unit/`. Run with `dbt test --select tag:unit_test`.
- **Generic tests**: Custom tests for PII detection and volume anomaly. Located in `dbt/tests/generic/`.
- **Source freshness**: Run `dbt source freshness` to validate ingestion timeliness.
- **elementary**: Stores test results in `TEST_RESULTS` schema for observability.

## Common dbt Commands

```bash
dbt deps                              # Install packages
dbt compile                           # Compile models (validation only)
dbt build                             # Run models + tests
dbt build --select staging+           # Build staging and downstream
dbt build --select state:modified+    # Build only modified models (CI)
dbt test                              # Run all tests
dbt test --select tag:unit_test       # Run unit tests only
dbt snapshot                          # Run SCD2 snapshots
dbt seed                              # Load seed CSV data
dbt docs generate                     # Generate documentation site
dbt source freshness                  # Check source freshness
```

## CI/CD Pipeline (GitHub Actions)

- **CI (on pull request)**: Runs `dbt build --select state:modified+` against `LIGHTHOUSE_STAGING_*` databases.
- **CD (on merge to main)**: Runs full `dbt build` against `LIGHTHOUSE_PROD_*` databases.
- Pipeline definitions live in `.github/workflows/`.

## Environment Strategy

| Environment | Database Prefix          | Purpose                       |
|-------------|--------------------------|-------------------------------|
| DEV         | `LIGHTHOUSE_DEV_*`       | Developer iteration, branches |
| STAGING     | `LIGHTHOUSE_STAGING_*`   | CI validation, PR builds      |
| PROD        | `LIGHTHOUSE_PROD_*`      | Production serving            |
