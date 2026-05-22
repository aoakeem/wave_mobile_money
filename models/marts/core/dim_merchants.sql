
select
    merchant_id,
    merchant_name,
    category,
    country,
    status,
    created_at,
    updated_at
from {{ ref('stg_merchants') }}
