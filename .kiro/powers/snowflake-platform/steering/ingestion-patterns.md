# Snowflake Ingestion Patterns

## Internal Stages

```sql
CREATE OR REPLACE STAGE {database}.{schema}.{stage_name}
  FILE_FORMAT = (TYPE = '{CSV|JSON|PARQUET}');
```

## File Formats

```sql
-- CSV format
CREATE OR REPLACE FILE FORMAT {database}.{schema}.csv_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL', 'null')
  EMPTY_FIELD_AS_NULL = TRUE;

-- JSON format (for IoT events)
CREATE OR REPLACE FILE FORMAT {database}.{schema}.json_format
  TYPE = 'JSON'
  STRIP_OUTER_ARRAY = TRUE;

-- Parquet format
CREATE OR REPLACE FILE FORMAT {database}.{schema}.parquet_format
  TYPE = 'PARQUET';
```

## COPY INTO Pattern

```sql
COPY INTO {database}.{schema}.{table}
FROM @{stage_name}/{path}/
FILE_FORMAT = (FORMAT_NAME = '{format_name}')
ON_ERROR = 'CONTINUE'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
```

## Metadata Columns for Lineage

Every raw table MUST include these metadata columns:

| Column | Type | Purpose |
|--------|------|---------|
| `_loaded_at` | TIMESTAMP_NTZ | Platform ingestion timestamp (DEFAULT CURRENT_TIMESTAMP()) |
| `_source_file_name` | VARCHAR | Source file name (for batch: METADATA$FILENAME) |
| `_source_file_row_number` | INTEGER | Row number in source file (for batch: METADATA$FILE_ROW_NUMBER) |
| `_connector_batch_id` | VARCHAR | Connector sync batch ID (for CDC/SaaS) |

## VARIANT Column Pattern (IoT/Semi-structured)

```sql
CREATE OR REPLACE TABLE {schema}.telemetry_events (
  event_data        VARIANT,
  device_id         VARCHAR(50),
  event_type        VARCHAR(50),
  event_timestamp   TIMESTAMP_NTZ,
  _loaded_at        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _ingestion_date   DATE DEFAULT CURRENT_DATE()
);
```

## Rules

- Raw tables MUST NOT apply any transformation — land data as-is
- Every raw table MUST have `_loaded_at` metadata column
- VARIANT columns MUST extract key fields as separate columns for query performance
- File formats MUST be defined as named objects, NOT inline in COPY INTO
- ON_ERROR SHOULD be 'CONTINUE' for batch loads with quarantine handling
