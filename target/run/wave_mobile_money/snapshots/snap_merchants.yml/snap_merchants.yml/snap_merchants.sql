
      update "wave"."main_snapshots"."snap_merchants" as DBT_INTERNAL_TARGET
    set dbt_valid_to = DBT_INTERNAL_SOURCE.dbt_valid_to
    from "snap_merchants__dbt_tmp20260521212718098462" as DBT_INTERNAL_SOURCE
    where DBT_INTERNAL_SOURCE.dbt_scd_id::text = DBT_INTERNAL_TARGET.dbt_scd_id::text
      and DBT_INTERNAL_SOURCE.dbt_change_type::text in ('update'::text, 'delete'::text)
      
        and DBT_INTERNAL_TARGET.dbt_valid_to is null;
      

    insert into "wave"."main_snapshots"."snap_merchants" ("merchant_id", "merchant_name", "category", "country", "status", "created_at", "updated_at", "dbt_updated_at", "dbt_valid_from", "dbt_valid_to", "dbt_scd_id")
    select DBT_INTERNAL_SOURCE."merchant_id",DBT_INTERNAL_SOURCE."merchant_name",DBT_INTERNAL_SOURCE."category",DBT_INTERNAL_SOURCE."country",DBT_INTERNAL_SOURCE."status",DBT_INTERNAL_SOURCE."created_at",DBT_INTERNAL_SOURCE."updated_at",DBT_INTERNAL_SOURCE."dbt_updated_at",DBT_INTERNAL_SOURCE."dbt_valid_from",DBT_INTERNAL_SOURCE."dbt_valid_to",DBT_INTERNAL_SOURCE."dbt_scd_id"
    from "snap_merchants__dbt_tmp20260521212718098462" as DBT_INTERNAL_SOURCE
    where DBT_INTERNAL_SOURCE.dbt_change_type::text = 'insert'::text;


  