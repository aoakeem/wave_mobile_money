
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select status
from (select * from "wave"."main_core"."fct_payments_history" where version_valid_from::date >= current_date - 1) dbt_subquery
where status is null



  
  
      
    ) dbt_internal_test