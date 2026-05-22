
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select kyc_tier
from "wave"."main_compliance"."mart_compliance_current"
where kyc_tier is null



  
  
      
    ) dbt_internal_test