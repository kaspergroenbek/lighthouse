{% test referential_integrity(model, column_name, to, field) %}
{#
    Generic test: validates that all non-null FK values in `column_name`
    exist in the referenced dimension table (`to`.`field`).
    Returns rows that violate referential integrity.

    Usage in YAML:
      tests:
        - referential_integrity:
            to: ref('dim_customer')
            field: customer_sk
#}

SELECT
    {{ column_name }} AS orphan_key
FROM {{ model }}
WHERE {{ column_name }} IS NOT NULL
  AND {{ column_name }} NOT IN (
      SELECT {{ field }} FROM {{ to }}
  )

{% endtest %}
