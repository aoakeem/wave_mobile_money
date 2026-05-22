
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_amount
from "wave"."main_kpi"."agg_payments_daily"
where total_amount is null



  
  
      
    ) dbt_internal_test