# Snowflake Semantic Views & Cortex AI Patterns

## CREATE SEMANTIC VIEW (Current Syntax)

Snowflake semantic views are first-class SQL objects. MUST NOT use the legacy YAML-on-stage approach.

```sql
CREATE OR REPLACE SEMANTIC VIEW {schema}.{name}

  TABLES (
    {alias} AS {database}.{schema}.{table}
      PRIMARY KEY ({pk_column})
      COMMENT = '{description}',
    -- additional tables...
  )

  RELATIONSHIPS (
    {name} AS {left_table} ({fk_column}) REFERENCES {right_table},
    -- additional relationships...
  )

  FACTS (
    {table}.{fact_name} AS {expression}
      COMMENT = '{description}',
    -- additional facts...
  )

  DIMENSIONS (
    {table}.{dim_name} AS {expression}
      WITH SYNONYMS = ('{synonym1}', '{synonym2}')
      COMMENT = '{description}',
    -- additional dimensions...
  )

  METRICS (
    {table}.{metric_name} AS {aggregation}({expression})
      COMMENT = '{description}',
    -- additional metrics...
  )

  COMMENT = '{semantic view description}';
```

## Key Rules for Semantic Views

- MUST define PRIMARY KEY on every table
- MUST define RELATIONSHIPS for all join paths
- SHOULD include COMMENT on all facts, dimensions, and metrics
- SHOULD include SYNONYMS on dimensions for natural-language flexibility
- MUST point to dbt mart models as the physical source (shared layer)
- MUST be deployed in the ANALYTICS.SEMANTIC schema

## Cortex Search Service

```sql
CREATE OR REPLACE CORTEX SEARCH SERVICE {service_name}
  ON {search_text_column}
  ATTRIBUTES {filter_col1}, {filter_col2}
  WAREHOUSE = AI_WH
  TARGET_LAG = '{lag}'
  AS (
    SELECT {columns}
    FROM {source_table}
  );
```

## Querying Cortex Search

```sql
SELECT *
FROM TABLE(
  {service_name}!SEARCH(
    query => '{natural language query}',
    columns => ['{col1}', '{col2}'],
    filter => {'@eq': {'{filter_col}': '{value}'}},
    limit => 5
  )
);
```

## Cortex Analyst

- Cortex Analyst reads from semantic views automatically
- No additional configuration needed beyond the semantic view definition
- Sample questions SHOULD be documented alongside the semantic view
- The semantic view MUST be accessible to the role running Cortex Analyst queries
