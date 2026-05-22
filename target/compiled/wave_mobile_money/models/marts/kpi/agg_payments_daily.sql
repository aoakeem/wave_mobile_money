

with affected_dates as (
    select distinct payment_date
    from "wave"."main_core"."fct_payments"
    
    
    
    where updated_at >= (
        select 

    (max(max_source_updated_at) + cast(-3 as bigint) * interval 1 hour)
        from "wave"."main_kpi"."agg_payments_daily"
    )
    

),

payments as (
    select p.*
    from "wave"."main_core"."fct_payments" p
    
    inner join affected_dates d on p.payment_date = d.payment_date
    
),

exchange_rates as (
    select
        currency,
        rate_date,
        rate_to_usd
    from "wave"."raw"."exchange_rates"
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