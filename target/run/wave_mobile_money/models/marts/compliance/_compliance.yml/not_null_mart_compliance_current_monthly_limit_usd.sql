
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select monthly_limit_usd
from "wave"."main_compliance"."mart_compliance_current"
where monthly_limit_usd is null



  
  
      
    ) dbt_internal_test