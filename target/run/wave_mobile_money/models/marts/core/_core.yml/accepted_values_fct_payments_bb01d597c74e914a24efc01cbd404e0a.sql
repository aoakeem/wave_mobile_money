
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        merchant_category as value_field,
        count(*) as n_records

    from "wave"."main_core"."fct_payments"
    group by merchant_category

)

select *
from all_values
where value_field not in (
    'supermarket','ecommerce','taxi','utility','other','none'
)



  
  
      
    ) dbt_internal_test