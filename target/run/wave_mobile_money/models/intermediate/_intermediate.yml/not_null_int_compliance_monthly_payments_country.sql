
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select country
from "wave"."main_intermediate"."int_compliance_monthly_payments"
where country is null



  
  
      
    ) dbt_internal_test