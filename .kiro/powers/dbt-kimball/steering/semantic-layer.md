# dbt Semantic Layer Patterns (v1.12+)

## Inline Semantic Model Configuration

```yaml
models:
  - name: fct_{process}
    semantic_model:
      enabled: true
    agg_time_dimension: {date_column}
    columns:
      - name: {process}_sk
        entity:
          name: {process}
          type: primary
      - name: customer_sk
        entity:
          name: customer
          type: foreign
      - name: {date_column}
        granularity: day
        dimension:
          type: time
      - name: amount
        data_type: number
    metrics:
      - name: total_revenue
        type: simple
        label: Total Revenue
        agg: sum
        expr: amount
```

## Metric Types

| Type | Use Case |
|------|----------|
| `simple` | Single measure aggregation (SUM, COUNT, AVG) |
| `cumulative` | Running totals over time |
| `derived` | Calculation from other metrics |
| `ratio` | Ratio of two metrics |

## Rules

- MUST use inline `semantic_model: enabled: true` (v1.12+)
- MUST define `agg_time_dimension` at model level
- MUST define primary entity on surrogate key, foreign entities on FKs
- Time dimensions MUST specify `granularity: day`
- Metrics MUST include `description` and `label`
