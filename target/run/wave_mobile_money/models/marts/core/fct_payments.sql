

    MERGE INTO "wave"."main_core"."fct_payments" AS DBT_INTERNAL_DEST
        USING "fct_payments__dbt_tmp20260521212718519032" AS DBT_INTERNAL_SOURCE
        
            
                
            
        
        ON (DBT_INTERNAL_SOURCE.payment_id = DBT_INTERNAL_DEST.payment_id)
    
    WHEN MATCHED
    THEN
        UPDATE BY NAME
    WHEN NOT MATCHED
        
    THEN
        INSERT BY NAME

  