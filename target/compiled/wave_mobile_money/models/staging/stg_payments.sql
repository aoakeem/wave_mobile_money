select
    payment_id,
    wallet_id,
    merchant_id,
    amount,
    currency,
    status,
    created_at,
    updated_at,
    country,
    channel
from "wave"."raw"."payments"