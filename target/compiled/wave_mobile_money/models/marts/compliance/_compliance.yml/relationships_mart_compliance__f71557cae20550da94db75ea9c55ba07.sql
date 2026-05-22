
    
    

with child as (
    select wallet_id as from_field
    from "wave"."main_compliance"."mart_compliance_current_transactions"
    where wallet_id is not null
),

parent as (
    select wallet_id as to_field
    from "wave"."main_compliance"."mart_compliance_current"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


