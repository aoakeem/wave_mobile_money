
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select payment_count
from "wave"."main_compliance"."mart_compliance_history"
where payment_count is null



  
  
      
    ) dbt_internal_test