
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select transacting_wallets
from "wave"."main_compliance"."mart_compliance_rate_history"
where transacting_wallets is null



  
  
      
    ) dbt_internal_test