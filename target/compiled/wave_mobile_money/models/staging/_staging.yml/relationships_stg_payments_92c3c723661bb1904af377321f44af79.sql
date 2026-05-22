
    
    

with child as (
    select merchant_id as from_field
    from (select * from "wave"."main_staging"."stg_payments" where merchant_id is not null and updated_at::date >= current_date - 1) dbt_subquery
    where merchant_id is not null
),

parent as (
    select merchant_id as to_field
    from "wave"."main_staging"."stg_merchants"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


