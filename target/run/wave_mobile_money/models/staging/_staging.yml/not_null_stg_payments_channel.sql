
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select channel
from (select * from "wave"."main_staging"."stg_payments" where updated_at::date >= current_date - 1) dbt_subquery
where channel is null



  
  
      
    ) dbt_internal_test