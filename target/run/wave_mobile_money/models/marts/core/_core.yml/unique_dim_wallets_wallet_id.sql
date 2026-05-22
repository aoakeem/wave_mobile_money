
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    wallet_id as unique_field,
    count(*) as n_records

from "wave"."main_core"."dim_wallets"
where wallet_id is not null
group by wallet_id
having count(*) > 1



  
  
      
    ) dbt_internal_test