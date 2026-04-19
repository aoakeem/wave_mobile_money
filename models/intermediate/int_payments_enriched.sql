{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='payment_id',
    cluster_by=['updated_at', 'payment_date']
) }}

with payments as (
    select * from {{ ref('stg_payments') }}
    {{ incremental_lookback('updated_at') }}
),

merchants as (
    select * from {{ ref('stg_merchants') }}
),

-- SCD2 snapshot resolves the kyc_tier and status valid at time of payment,
-- enabling accurate historical KPI breakdowns by tier.
-- Compliance models use stg_wallets (current tier) separately.
wallets as (
    select * from {{ ref('snap_wallets') }}
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
    p.created_at::date                          as payment_date,
    p.country,
    p.channel,
    coalesce(m.category, 'none')                as merchant_category,
    w.kyc_tier,
    w.is_agent
from payments p
left join merchants m
    on p.merchant_id = m.merchant_id
left join wallets w
    on p.wallet_id = w.wallet_id
    and p.created_at >= w.dbt_valid_from
    and (p.created_at < w.dbt_valid_to or w.dbt_valid_to is null)
