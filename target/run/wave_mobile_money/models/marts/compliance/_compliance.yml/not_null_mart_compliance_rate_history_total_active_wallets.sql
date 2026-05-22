
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_active_wallets
from "wave"."main_compliance"."mart_compliance_rate_history"
where total_active_wallets is null



  
  
      
    ) dbt_internal_test