
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        kyc_tier as value_field,
        count(*) as n_records

    from "wave"."main_compliance"."mart_compliance_current"
    group by kyc_tier

)

select *
from all_values
where value_field not in (
    '0','1','2'
)



  
  
      
    ) dbt_internal_test