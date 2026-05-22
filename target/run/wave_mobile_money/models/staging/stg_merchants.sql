
  
  create view "wave"."main_staging"."stg_merchants__dbt_tmp" as (
    select
    merchant_id,
    merchant_name,
    category,
    country,
    status,
    created_at,
    updated_at
from "wave"."raw"."merchants"
  );
