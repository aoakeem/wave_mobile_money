
    
    

select
    wallet_id as unique_field,
    count(*) as n_records

from "wave"."main_core"."dim_wallets"
where wallet_id is not null
group by wallet_id
having count(*) > 1


