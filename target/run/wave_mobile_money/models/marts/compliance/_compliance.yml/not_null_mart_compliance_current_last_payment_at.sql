
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select last_payment_at
from "wave"."main_compliance"."mart_compliance_current"
where last_payment_at is null



  
  
      
    ) dbt_internal_test