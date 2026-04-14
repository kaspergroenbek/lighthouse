{% test surrogate_key_collision(model, column_name, natural_key_columns) %}
{#
    Generic test: detects hash collisions in surrogate keys by checking
    whether distinct natural key combinations map to the same surrogate key.

    Usage in YAML:
      tests:
        - surrogate_key_collision:
            natural_key_columns: ['customer_id', 'valid_from']
#}

WITH key_pairs AS (
    SELECT
        {{ column_name }} AS surrogate_key,
        {{ natural_key_columns | join(", ") }}
    FROM {{ model }}
),

collision_check AS (
    SELECT
        surrogate_key,
        COUNT(DISTINCT {{ natural_key_columns | join(" || '|' || ") }}) AS distinct_natural_keys
    FROM key_pairs
    GROUP BY surrogate_key
    HAVING COUNT(DISTINCT {{ natural_key_columns | join(" || '|' || ") }}) > 1
)

SELECT * FROM collision_check

{% endtest %}
