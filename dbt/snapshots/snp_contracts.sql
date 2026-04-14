{% snapshot snp_contracts %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='contract_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

SELECT * FROM {{ ref('stg_oltp__contracts') }}

{% endsnapshot %}
