
    
    

with all_values as (

    select
        channel as value_field,
        count(*) as n_records

    from "wave"."main_core"."fct_payments"
    group by channel

)

select *
from all_values
where value_field not in (
    'ussd','app','agent'
)


