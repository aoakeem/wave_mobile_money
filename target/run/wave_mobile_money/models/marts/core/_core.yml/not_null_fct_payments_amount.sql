
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select amount
from (select * from "wave"."main_core"."fct_payments" where updated_at::date >= current_date - 1) dbt_subquery
where amount is null



  
  
      
    ) dbt_internal_test