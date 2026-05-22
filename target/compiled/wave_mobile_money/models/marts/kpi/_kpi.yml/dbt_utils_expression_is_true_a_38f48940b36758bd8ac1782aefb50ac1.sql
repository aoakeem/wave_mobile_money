



select
    1
from "wave"."main_kpi"."agg_payments_daily"

where not(payment_count > 0)

