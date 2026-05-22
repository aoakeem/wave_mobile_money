
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select max_source_updated_at
from "wave"."main_kpi"."agg_payments_daily"
where max_source_updated_at is null



  
  
      
    ) dbt_internal_test