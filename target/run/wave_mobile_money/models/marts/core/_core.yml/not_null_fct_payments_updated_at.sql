
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select updated_at
from (select * from "wave"."main_core"."fct_payments" where updated_at::date >= current_date - 1) dbt_subquery
where updated_at is null



  
  
      
    ) dbt_internal_test