
    
    

select
    payment_id as unique_field,
    count(*) as n_records

from "wave"."main_intermediate"."int_compliance_monthly_payments"
where payment_id is not null
group by payment_id
having count(*) > 1


