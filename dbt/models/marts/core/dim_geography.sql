WITH households AS (
    SELECT DISTINCT
        postal_code,
        municipality,
        country
    FROM {{ ref('stg_oltp__households') }}
    WHERE postal_code IS NOT NULL
),

customers AS (
    SELECT DISTINCT
        postal_code,
        municipality,
        region,
        country
    FROM {{ ref('stg_oltp__customers') }}
    WHERE postal_code IS NOT NULL
),

combined AS (
    SELECT
        COALESCE(c.postal_code, h.postal_code) AS postal_code,
        COALESCE(c.municipality, h.municipality) AS municipality,
        c.region,
        COALESCE(c.country, h.country) AS country
    FROM customers c
    FULL OUTER JOIN households h
        ON c.postal_code = h.postal_code
        AND c.municipality = h.municipality
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['postal_code', 'municipality', 'country']) }} AS geography_sk,
        postal_code,
        municipality,
        region,
        country
    FROM combined
)

SELECT * FROM final
