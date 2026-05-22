
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select channel
from "wave"."main_kpi"."agg_payments_daily"
where channel is null



  
  
      
    ) dbt_internal_test