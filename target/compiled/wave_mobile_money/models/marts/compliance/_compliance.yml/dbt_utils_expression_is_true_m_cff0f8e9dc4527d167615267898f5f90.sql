



select
    1
from "wave"."main_compliance"."mart_compliance_current"

where not(monthly_volume_usd > 0)

