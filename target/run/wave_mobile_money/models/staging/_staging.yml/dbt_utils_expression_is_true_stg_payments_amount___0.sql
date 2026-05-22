
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from (select * from "wave"."main_staging"."stg_payments" where updated_at::date >= current_date - 1) dbt_subquery

where not(amount >= 0)


  
  
      
    ) dbt_internal_test