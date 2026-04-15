{#
    Singular test: asserts that all columns tagged with CLASSIFICATION = 'PII'
    in the MARTS schema have a corresponding Snowflake masking policy applied.

    This test queries Snowflake's INFORMATION_SCHEMA to compare tagged columns
    against policy references. Returns unmasked PII columns.
#}

WITH pii_tagged_columns AS (
    SELECT
        tr.object_database,
        tr.object_schema,
        tr.object_name   AS table_name,
        tr.column_name
    FROM TABLE(INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
        '{{ target.database }}.MARTS',
        'SCHEMA'
    )) tr
    WHERE tr.tag_name = 'CLASSIFICATION'
      AND tr.tag_value = 'PII'
),

masked_columns AS (
    SELECT
        ref_database_name  AS object_database,
        ref_schema_name    AS object_schema,
        ref_entity_name    AS table_name,
        ref_column_name    AS column_name
    FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(
        ref_entity_domain => 'SCHEMA',
        ref_entity_name   => '{{ target.database }}.MARTS'
    ))
    WHERE policy_kind = 'MASKING_POLICY'
      AND ref_column_name IS NOT NULL
),

unmasked_pii AS (
    SELECT
        p.table_name,
        p.column_name
    FROM pii_tagged_columns p
    LEFT JOIN masked_columns m
        ON  p.table_name  = m.table_name
        AND p.column_name = m.column_name
    WHERE m.column_name IS NULL
)

SELECT * FROM unmasked_pii
