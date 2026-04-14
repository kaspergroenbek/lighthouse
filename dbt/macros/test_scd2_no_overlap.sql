{% test scd2_no_overlap(model, column_name, natural_key, valid_from='valid_from', valid_to='valid_to') %}
{#
    Generic test: validates no overlapping valid_from/valid_to ranges
    for the same natural key in SCD Type 2 dimensions.

    `column_name` is the surrogate key (used as the test anchor column).

    Usage in YAML:
      tests:
        - scd2_no_overlap:
            natural_key: customer_id
            valid_from: valid_from
            valid_to: valid_to
#}

WITH versioned AS (
    SELECT
        {{ natural_key }},
        {{ valid_from }},
        {{ valid_to }}
    FROM {{ model }}
),

overlaps AS (
    SELECT
        a.{{ natural_key }},
        a.{{ valid_from }} AS a_valid_from,
        a.{{ valid_to }}   AS a_valid_to,
        b.{{ valid_from }} AS b_valid_from,
        b.{{ valid_to }}   AS b_valid_to
    FROM versioned a
    INNER JOIN versioned b
        ON  a.{{ natural_key }} = b.{{ natural_key }}
        AND a.{{ valid_from }} < b.{{ valid_from }}
        AND (a.{{ valid_to }} IS NULL OR a.{{ valid_to }} > b.{{ valid_from }})
)

SELECT * FROM overlaps

{% endtest %}
