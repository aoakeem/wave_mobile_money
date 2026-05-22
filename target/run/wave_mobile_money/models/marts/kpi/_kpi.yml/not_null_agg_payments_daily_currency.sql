
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select currency
from "wave"."main_kpi"."agg_payments_daily"
where currency is null



  
  
      
    ) dbt_internal_test