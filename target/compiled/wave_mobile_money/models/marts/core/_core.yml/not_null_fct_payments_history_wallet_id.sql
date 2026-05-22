
    
    



select wallet_id
from (select * from "wave"."main_core"."fct_payments_history" where version_valid_from::date >= current_date - 1) dbt_subquery
where wallet_id is null


