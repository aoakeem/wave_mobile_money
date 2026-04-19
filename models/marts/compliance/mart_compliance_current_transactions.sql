{{ config(materialized='table') }}

select
    p.payment_id,
    p.wallet_id,
    p.amount,
    p.currency,
    p.amount_usd,
    p.created_at,
    p.country,
    p.channel,
    p.merchant_id,
    p.merchant_category,
    p.kyc_tier,
    b.checked_at
from {{ ref('int_compliance_monthly_payments') }} p
inner join {{ ref('mart_compliance_current') }} b on p.wallet_id = b.wallet_id
