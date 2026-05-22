{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}

with active_wallets as (
    select count(*) as total_active_wallets
    from {{ ref('dim_wallets') }}
    where status = 'active'
),

transacting as (
    select count(distinct wallet_id) as transacting_wallets
    from {{ ref('int_compliance_monthly_payments') }}
),

breaching as (
    select
        count(*)        as breaching_wallets,
        max(checked_at) as checked_at
    from {{ ref('mart_compliance_current') }}
)

select
    b.checked_at,
    a.total_active_wallets,
    t.transacting_wallets,
    b.breaching_wallets,
    case
        when t.transacting_wallets = 0 then null
        else b.breaching_wallets::float / t.transacting_wallets
    end                                                                         as breach_rate
from active_wallets a, transacting t, breaching b
