

select
    payment_id,
    wallet_id,
    merchant_id,
    amount,
    currency,
    status,
    country,
    channel,
    created_at,
    updated_at as version_valid_from
from "wave"."main_staging"."stg_payments"

    
    
    where updated_at >= (
        select 

    (max(updated_at) + cast(-3 as bigint) * interval 1 hour)
        from "wave"."main_core"."fct_payments_history"
    )
    
