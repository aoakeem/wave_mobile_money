
    
    



select status
from (select * from "wave"."main_core"."fct_payments" where updated_at::date >= current_date - 1) dbt_subquery
where status is null


