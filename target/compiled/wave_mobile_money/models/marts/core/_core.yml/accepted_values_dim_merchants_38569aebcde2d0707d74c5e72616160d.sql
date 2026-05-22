
    
    

with all_values as (

    select
        category as value_field,
        count(*) as n_records

    from "wave"."main_core"."dim_merchants"
    group by category

)

select *
from all_values
where value_field not in (
    'supermarket','ecommerce','taxi','utility','other'
)


