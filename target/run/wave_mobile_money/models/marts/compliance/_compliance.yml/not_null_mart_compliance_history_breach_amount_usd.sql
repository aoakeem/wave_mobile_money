
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select breach_amount_usd
from "wave"."main_compliance"."mart_compliance_history"
where breach_amount_usd is null



  
  
      
    ) dbt_internal_test