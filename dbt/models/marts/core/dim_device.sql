WITH lifecycle AS (
    SELECT * FROM {{ ref('int_device__lifecycle') }}
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['device_id']) }} AS device_sk,
        device_id,
        device_serial,
        household_id,
        device_type,
        manufacturer,
        model,
        firmware_version,
        installed_at,
        lifecycle_state,
        created_at,
        updated_at
    FROM lifecycle
)

SELECT * FROM final
