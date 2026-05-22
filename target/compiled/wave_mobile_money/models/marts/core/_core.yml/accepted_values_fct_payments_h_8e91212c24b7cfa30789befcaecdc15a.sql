
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from "wave"."main_core"."fct_payments_history"
    group by status

)

select *
from all_values
where value_field not in (
    'success','failed','reversed'
)


