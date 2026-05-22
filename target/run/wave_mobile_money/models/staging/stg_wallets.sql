
  
  create view "wave"."main_staging"."stg_wallets__dbt_tmp" as (
    select
    wallet_id,
    user_created_at,
    kyc_tier,
    country,
    is_agent,
    status,
    updated_at
from "wave"."raw"."wallets"
  );
