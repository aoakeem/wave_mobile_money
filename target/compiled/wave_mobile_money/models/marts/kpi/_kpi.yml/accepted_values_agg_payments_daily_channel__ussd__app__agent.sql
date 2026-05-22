
    
    

with all_values as (

    select
        channel as value_field,
        count(*) as n_records

    from "wave"."main_kpi"."agg_payments_daily"
    group by channel

)

select *
from all_values
where value_field not in (
    'ussd','app','agent'
)


