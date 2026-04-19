{{ config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='payment_date',
    cluster_by=['payment_date']
) }}

with affected_dates as (
    select distinct payment_date
    from {{ ref('int_payments_enriched') }}
    {% if is_incremental() %}
    where updated_at >= (
        select dateadd(
            hour,
            -{{ var('incremental_lookback_hours', 3) }},
            max(last_loaded_at)
        )
        from {{ this }}
    )
    {% endif %}
),

payments as (
    select p.*
    from {{ ref('int_payments_enriched') }} p
    {% if is_incremental() %}
    inner join affected_dates d on p.payment_date = d.payment_date
    {% endif %}
)

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
    current_timestamp()                     as last_loaded_at
from payments
group by 1, 2, 3, 4, 5, 6, 7
