WITH devices AS (
    SELECT * FROM {{ ref('int_device__lifecycle') }}
),

households AS (
    SELECT * FROM {{ ref('dim_household') }}
),

dim_devices AS (
    SELECT * FROM {{ ref('dim_device') }}
),

final AS (
    SELECT
        h.household_sk,
        d.device_sk,
        devices.device_id,
        devices.household_id,
        devices.installed_at AS effective_from,
        CASE
            WHEN devices.lifecycle_state = 'decommissioned' THEN devices.updated_at
            ELSE NULL
        END AS effective_to
    FROM devices
    INNER JOIN households h ON devices.household_id = h.household_id
    INNER JOIN dim_devices d ON devices.device_id = d.device_id
)

SELECT * FROM final
