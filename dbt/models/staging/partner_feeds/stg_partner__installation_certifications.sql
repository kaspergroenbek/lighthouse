WITH source AS (
    SELECT * FROM {{ source('partner_feeds', 'installation_certifications') }}
),

renamed AS (
    SELECT
        -- Keys
        certification_id,

        -- Attributes
        installation_id,
        installer_id,
        CAST(certification_date AS DATE) AS certification_date,
        certification_type,
        CAST(expiry_date AS DATE) AS expiry_date,
        status,
        inspector_name,

        -- Metadata
        _loaded_at,
        _source_file_name,
        _source_file_row_number

    FROM source
)

SELECT * FROM renamed
