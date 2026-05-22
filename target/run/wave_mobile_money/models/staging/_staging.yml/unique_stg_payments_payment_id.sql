
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    payment_id as unique_field,
    count(*) as n_records

from (select * from "wave"."main_staging"."stg_payments" where updated_at::date >= current_date - 1) dbt_subquery
where payment_id is not null
group by payment_id
having count(*) > 1



  
  
      
    ) dbt_internal_test