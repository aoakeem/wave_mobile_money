
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select country
from "wave"."main_staging"."stg_merchants"
where country is null



  
  
      
    ) dbt_internal_test