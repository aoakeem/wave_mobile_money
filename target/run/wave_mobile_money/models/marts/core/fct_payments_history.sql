
  
    
    

    create  table
      "wave"."main_core"."fct_payments_history"
  
    as (
      

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

    

    );
  
  
  