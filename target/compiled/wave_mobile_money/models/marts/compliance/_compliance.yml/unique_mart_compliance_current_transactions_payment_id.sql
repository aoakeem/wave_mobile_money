
    
    

select
    payment_id as unique_field,
    count(*) as n_records

from "wave"."main_compliance"."mart_compliance_current_transactions"
where payment_id is not null
group by payment_id
having count(*) > 1


