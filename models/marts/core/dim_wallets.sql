select
    wallet_id,
    user_created_at,
    kyc_tier,
    country,
    is_agent,
    status,
    updated_at
from {{ ref('stg_wallets') }}
