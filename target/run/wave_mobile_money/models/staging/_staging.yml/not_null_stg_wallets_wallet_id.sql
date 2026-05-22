
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select wallet_id
from "wave"."main_staging"."stg_wallets"
where wallet_id is null



  
  
      
    ) dbt_internal_test