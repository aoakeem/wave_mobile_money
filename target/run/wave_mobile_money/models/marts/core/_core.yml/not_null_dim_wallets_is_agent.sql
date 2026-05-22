
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select is_agent
from "wave"."main_core"."dim_wallets"
where is_agent is null



  
  
      
    ) dbt_internal_test