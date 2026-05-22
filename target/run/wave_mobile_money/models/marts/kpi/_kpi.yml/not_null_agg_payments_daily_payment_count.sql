
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select payment_count
from "wave"."main_kpi"."agg_payments_daily"
where payment_count is null



  
  
      
    ) dbt_internal_test