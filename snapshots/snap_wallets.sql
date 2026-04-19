{% snapshot snap_wallets %}

{{
    config(
        target_schema='snapshots',
        unique_key='wallet_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=False
    )
}}

select
    wallet_id,
    user_created_at,
    kyc_tier,
    country,
    is_agent,
    status,
    updated_at
from {{ source('raw', 'wallets') }}

{% endsnapshot %}
