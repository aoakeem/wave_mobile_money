
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from "wave"."main_kpi"."agg_payments_daily"

where not(payment_count > 0)


  
  
      
    ) dbt_internal_test