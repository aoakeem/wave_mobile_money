

with payments as (
    select
        payment_id,
        wallet_id,
        merchant_id,
        amount,
        currency,
        status,
        created_at,
        updated_at,
        country,
        channel
    from "wave"."main_staging"."stg_payments"
    
    
    
    where updated_at >= (
        select 

    (max(updated_at) + cast(-3 as bigint) * interval 1 hour)
        from "wave"."main_core"."fct_payments"
    )
    

),

-- SCD2 snapshots resolve dimension attributes valid at time of payment,
-- enabling accurate historical KPI breakdowns by merchant category and KYC tier.
merchants as (
    select
        merchant_id,
        category,
        dbt_valid_from,
        dbt_valid_to
    from "wave"."main_snapshots"."snap_merchants"
),

wallets as (
    select
        wallet_id,
        kyc_tier,
        is_agent,
        dbt_valid_from,
        dbt_valid_to
    from "wave"."main_snapshots"."snap_wallets"
)

select
    p.payment_id,
    p.wallet_id,
    p.merchant_id,
    p.amount,
    p.currency,
    p.status,
    p.created_at,
    p.updated_at,
    p.created_at::date                as payment_date,
    p.country,
    p.channel,
    coalesce(m.category, 'none')      as merchant_category,
    w.kyc_tier,
    w.is_agent
from payments p
left join merchants m
    on p.merchant_id = m.merchant_id
    and p.created_at >= m.dbt_valid_from
    and (p.created_at < m.dbt_valid_to or m.dbt_valid_to is null)
left join wallets w
    on p.wallet_id = w.wallet_id
    and p.created_at >= w.dbt_valid_from
    and (p.created_at < w.dbt_valid_to or w.dbt_valid_to is null)