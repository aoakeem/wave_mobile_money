{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='payment_id',
    cluster_by=['updated_at']
) }}

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
from {{ source('raw', 'payments') }}

{{ incremental_lookback('updated_at') }}
