
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from "wave"."main_compliance"."mart_compliance_history"

where not(breach_amount_usd > 0)


  
  
      
    ) dbt_internal_test