
      update "wave"."main_snapshots"."snap_wallets" as DBT_INTERNAL_TARGET
    set dbt_valid_to = DBT_INTERNAL_SOURCE.dbt_valid_to
    from "snap_wallets__dbt_tmp20260521212718145381" as DBT_INTERNAL_SOURCE
    where DBT_INTERNAL_SOURCE.dbt_scd_id::text = DBT_INTERNAL_TARGET.dbt_scd_id::text
      and DBT_INTERNAL_SOURCE.dbt_change_type::text in ('update'::text, 'delete'::text)
      
        and DBT_INTERNAL_TARGET.dbt_valid_to is null;
      

    insert into "wave"."main_snapshots"."snap_wallets" ("wallet_id", "user_created_at", "kyc_tier", "country", "is_agent", "status", "updated_at", "dbt_updated_at", "dbt_valid_from", "dbt_valid_to", "dbt_scd_id")
    select DBT_INTERNAL_SOURCE."wallet_id",DBT_INTERNAL_SOURCE."user_created_at",DBT_INTERNAL_SOURCE."kyc_tier",DBT_INTERNAL_SOURCE."country",DBT_INTERNAL_SOURCE."is_agent",DBT_INTERNAL_SOURCE."status",DBT_INTERNAL_SOURCE."updated_at",DBT_INTERNAL_SOURCE."dbt_updated_at",DBT_INTERNAL_SOURCE."dbt_valid_from",DBT_INTERNAL_SOURCE."dbt_valid_to",DBT_INTERNAL_SOURCE."dbt_scd_id"
    from "snap_wallets__dbt_tmp20260521212718145381" as DBT_INTERNAL_SOURCE
    where DBT_INTERNAL_SOURCE.dbt_change_type::text = 'insert'::text;


  