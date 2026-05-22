{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}

select
    wallet_id,
    country,
    kyc_tier,
    is_agent,
    monthly_volume_usd,
    monthly_limit_usd,
    breach_amount_usd,
    payment_count,
    checked_at
from {{ ref('mart_compliance_current') }}
