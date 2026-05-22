
    
    



select channel
from (select * from "wave"."main_staging"."stg_payments" where updated_at::date >= current_date - 1) dbt_subquery
where channel is null


