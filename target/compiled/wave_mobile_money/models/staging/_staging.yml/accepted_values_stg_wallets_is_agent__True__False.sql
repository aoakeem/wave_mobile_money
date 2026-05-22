
    
    

with all_values as (

    select
        is_agent as value_field,
        count(*) as n_records

    from "wave"."main_staging"."stg_wallets"
    group by is_agent

)

select *
from all_values
where value_field not in (
    'True','False'
)


