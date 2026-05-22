
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select merchant_category
from "wave"."main_compliance"."mart_compliance_current_transactions"
where merchant_category is null



  
  
      
    ) dbt_internal_test