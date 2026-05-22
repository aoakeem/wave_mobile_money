
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select channel
from "wave"."main_intermediate"."int_compliance_monthly_payments"
where channel is null



  
  
      
    ) dbt_internal_test