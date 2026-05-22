

with wallet_monthly_volumes as (
    select
        wallet_id,
        sum(amount_usd)  as monthly_volume_usd,
        count(*)         as payment_count,
        max(created_at)  as last_payment_at
    from "wave"."main_intermediate"."int_compliance_monthly_payments"
    group by wallet_id
),

wallets as (
    select
        wallet_id,
        country,
        kyc_tier,
        is_agent
    from "wave"."main_core"."dim_wallets"
),

limits as (
    select
        kyc_tier,
        monthly_limit_usd
    from "wave"."main"."kyc_limits"
)

select
    w.wallet_id,
    w.country,
    w.kyc_tier,
    w.is_agent,
    mv.monthly_volume_usd,
    l.monthly_limit_usd,
    mv.monthly_volume_usd - l.monthly_limit_usd  as breach_amount_usd,
    mv.payment_count,
    mv.last_payment_at,
    now()                as checked_at
from wallet_monthly_volumes mv
inner join wallets w on mv.wallet_id = w.wallet_id
inner join limits l on w.kyc_tier = l.kyc_tier
where mv.monthly_volume_usd > l.monthly_limit_usd