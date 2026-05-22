
    
    

with all_values as (

    select
        merchant_category as value_field,
        count(*) as n_records

    from "wave"."main_compliance"."mart_compliance_current_transactions"
    group by merchant_category

)

select *
from all_values
where value_field not in (
    'supermarket','ecommerce','taxi','utility','other','none'
)


