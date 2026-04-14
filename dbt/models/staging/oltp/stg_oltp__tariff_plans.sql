WITH source AS (
    SELECT * FROM {{ source('oltp', 'tariff_plans') }}
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY tariff_plan_id
            ORDER BY _source_ts DESC
        ) AS _row_num
    FROM source
    WHERE _op != 'DELETE'
),

renamed AS (
    SELECT
        -- Keys
        tariff_plan_id,

        -- Attributes
        plan_name,
        plan_type,
        CAST(price_per_kwh AS NUMBER(12, 2)) AS price_per_kwh,
        CAST(monthly_base_fee AS NUMBER(12, 2)) AS monthly_base_fee,
        CAST(valid_from AS DATE) AS valid_from,
        CAST(valid_to AS DATE) AS valid_to,
        CAST(created_at AS TIMESTAMP_NTZ) AS created_at,
        CAST(updated_at AS TIMESTAMP_NTZ) AS updated_at,

        -- Metadata
        _source_ts,
        _loaded_at,
        _connector_batch_id

    FROM deduplicated
    WHERE _row_num = 1
)

SELECT * FROM renamed
