

with payments as (
    select
        payment_id,
        wallet_id,
        amount,
        currency,
        created_at,
        country,
        channel,
        merchant_id,
        merchant_category,
        kyc_tier
    from "wave"."main_core"."fct_payments"
    where status = 'success'
    and date_trunc('month', created_at) = date_trunc('month', current_date)
),

exchange_rates as (
    select
        currency,
        rate_date,
        rate_to_usd
    from "wave"."raw"."exchange_rates"
)

select
    p.payment_id,
    p.wallet_id,
    p.amount,
    p.currency,
    p.amount * er.rate_to_usd  as amount_usd,
    p.created_at,
    p.country,
    p.channel,
    p.merchant_id,
    p.merchant_category,
    p.kyc_tier
from payments p
left join exchange_rates er
    on er.currency = p.currency
    and er.rate_date = (
        select max(rate_date)
        from exchange_rates
        where currency = p.currency
        and rate_date <= p.created_at::date
    )