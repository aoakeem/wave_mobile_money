{{ config(
    incremental_strategy='delete+insert',
    unique_key='payment_date',
    materialized='incremental',
    cluster_by=['payment_date']
) }}

with affected_dates as (
    select distinct payment_date
    from {{ ref('fct_payments') }}
    {{ incremental_lookback('updated_at', 'max_source_updated_at') }}
),

payments as (
    select p.*
    from {{ ref('fct_payments') }} p
    {% if is_incremental() %}
    inner join affected_dates d on p.payment_date = d.payment_date
    {% endif %}
),

exchange_rates as (
    select
        currency,
        rate_date,
        rate_to_usd
    from {{ source('raw', 'exchange_rates') }}
),

agg as (
    select
        payment_date,
        country,
        currency,
        status,
        channel,
        merchant_category,
        coalesce(kyc_tier::varchar, 'unknown')  as kyc_tier,
        count(*)                                as payment_count,
        sum(amount)                             as total_amount,
        max(updated_at)                         as max_source_updated_at
    from payments
    group by 1, 2, 3, 4, 5, 6, 7
)

select
    a.payment_date,
    a.country,
    a.currency,
    a.status,
    a.channel,
    a.merchant_category,
    a.kyc_tier,
    a.payment_count,
    a.total_amount,
    a.total_amount * er.rate_to_usd         as total_amount_usd,
    a.max_source_updated_at
from agg a
left join exchange_rates er
    on er.currency = a.currency
    and er.rate_date = (
        select max(rate_date)
        from exchange_rates
        where currency = a.currency
        and rate_date <= a.payment_date
    )
