WITH source AS (
    SELECT * FROM {{ source('partner_feeds', 'grid_usage_readings') }}
),

renamed AS (
    SELECT
        -- Keys
        reading_id,

        -- Attributes
        meter_id,
        household_id,
        CAST(reading_date AS DATE) AS reading_date,
        kwh_consumed::NUMBER(12,2) AS kwh_consumed,
        kwh_produced::NUMBER(12,2) AS kwh_produced,
        peak_demand_kw::NUMBER(12,2) AS peak_demand_kw,
        reading_source,

        -- Metadata
        _loaded_at,
        _source_file_name,
        _source_file_row_number

    FROM source
)

SELECT * FROM renamed
