
    
    

with all_values as (

    select
        kyc_tier as value_field,
        count(*) as n_records

    from "wave"."main_staging"."stg_wallets"
    group by kyc_tier

)

select *
from all_values
where value_field not in (
    '0','1','2'
)


