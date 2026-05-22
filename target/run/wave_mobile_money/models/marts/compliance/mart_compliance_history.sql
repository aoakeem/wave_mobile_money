
  
    
    

    create  table
      "wave"."main_compliance"."mart_compliance_history"
  
    as (
      

select
    wallet_id,
    country,
    kyc_tier,
    is_agent,
    monthly_volume_usd,
    monthly_limit_usd,
    breach_amount_usd,
    payment_count,
    checked_at
from "wave"."main_compliance"."mart_compliance_current"
    );
  
  
  