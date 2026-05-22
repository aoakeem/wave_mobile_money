
    
    

select
    wallet_id as unique_field,
    count(*) as n_records

from "wave"."main_compliance"."mart_compliance_current"
where wallet_id is not null
group by wallet_id
having count(*) > 1


