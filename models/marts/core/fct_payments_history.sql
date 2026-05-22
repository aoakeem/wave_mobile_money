{{ config(
    incremental_strategy='delete+insert',
    materialized='incremental',
    unique_key=['payment_id', 'version_valid_from']
) }}

select
    payment_id,
    wallet_id,
    merchant_id,
    amount,
    currency,
    status,
    country,
    channel,
    created_at,
    updated_at as version_valid_from
from {{ ref('stg_payments') }}
{{ incremental_lookback('updated_at') }}
