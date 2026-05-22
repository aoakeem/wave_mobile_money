



select
    1
from "wave"."main_compliance"."mart_compliance_current"

where not(breach_amount_usd > 0)

