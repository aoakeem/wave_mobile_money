
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from "wave"."main_staging"."stg_wallets"
    group by status

)

select *
from all_values
where value_field not in (
    'active','inactive','blocked'
)


