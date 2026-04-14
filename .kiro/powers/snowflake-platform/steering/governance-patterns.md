# Snowflake Governance Patterns

## Object Tags (Classification)

```sql
CREATE TAG IF NOT EXISTS LIGHTHOUSE.GOVERNANCE.CLASSIFICATION
  ALLOWED_VALUES 'PII', 'SENSITIVE', 'INTERNAL', 'PUBLIC';

-- Apply to columns
ALTER TABLE {table} MODIFY COLUMN {column}
  SET TAG LIGHTHOUSE.GOVERNANCE.CLASSIFICATION = '{value}';
```

## Dynamic Data Masking

```sql
-- String masking (PII)
CREATE OR REPLACE MASKING POLICY pii_string_mask AS (val STRING)
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ENGINEER', 'LIGHTHOUSE_ADMIN')
    THEN val
    ELSE '***MASKED***'
  END;

-- Date masking
CREATE OR REPLACE MASKING POLICY pii_date_mask AS (val DATE)
RETURNS DATE ->
  CASE
    WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ENGINEER', 'LIGHTHOUSE_ADMIN')
    THEN val
    ELSE NULL
  END;

-- Number masking (sensitive financial)
CREATE OR REPLACE MASKING POLICY sensitive_number_mask AS (val NUMBER)
RETURNS NUMBER ->
  CASE
    WHEN CURRENT_ROLE() IN ('LIGHTHOUSE_ENGINEER', 'LIGHTHOUSE_ADMIN')
    THEN val
    ELSE NULL
  END;

-- Apply to column
ALTER TABLE {table} MODIFY COLUMN {column}
  SET MASKING POLICY pii_string_mask;
```

## Row Access Policies

```sql
CREATE OR REPLACE ROW ACCESS POLICY region_access_policy AS (region_col VARCHAR)
RETURNS BOOLEAN ->
  CURRENT_ROLE() IN ('LIGHTHOUSE_ENGINEER', 'LIGHTHOUSE_ADMIN')
  OR region_col = CURRENT_SESSION()::VARIANT:region::VARCHAR;

-- Apply to table
ALTER TABLE {table} ADD ROW ACCESS POLICY region_access_policy ON (region);
```

## Rules

- Masking policies MUST use role-based conditions (not user-based)
- LIGHTHOUSE_READER MUST see masked values for PII columns
- LIGHTHOUSE_ENGINEER and above MUST see unmasked values
- All governance objects MUST be in `snowflake/governance/` directory
- All governance SQL MUST be idempotent (`CREATE OR REPLACE`)
- PII columns: customer name, email, phone, address
- SENSITIVE columns: invoice amounts, payment details
