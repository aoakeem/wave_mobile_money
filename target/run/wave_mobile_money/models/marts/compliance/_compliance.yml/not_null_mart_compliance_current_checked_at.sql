
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select checked_at
from "wave"."main_compliance"."mart_compliance_current"
where checked_at is null



  
  
      
    ) dbt_internal_test