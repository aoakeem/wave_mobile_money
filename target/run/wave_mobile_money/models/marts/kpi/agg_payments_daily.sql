
        
            delete from "wave"."main_kpi"."agg_payments_daily"
            where (
                payment_date) in (
                select (payment_date)
                from "agg_payments_daily__dbt_tmp20260521212718929183"
            );

        
    

    insert into "wave"."main_kpi"."agg_payments_daily" ("payment_date", "country", "currency", "status", "channel", "merchant_category", "kyc_tier", "payment_count", "total_amount", "total_amount_usd", "max_source_updated_at")
    (
        select "payment_date", "country", "currency", "status", "channel", "merchant_category", "kyc_tier", "payment_count", "total_amount", "total_amount_usd", "max_source_updated_at"
        from "agg_payments_daily__dbt_tmp20260521212718929183"
    )
  