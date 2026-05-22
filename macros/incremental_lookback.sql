{% macro incremental_lookback(timestamp_col, watermark_col=none) %}
    {% if is_incremental() %}
    where {{ timestamp_col }} >= (
        select dateadd(
            hour,
            -{{ var('incremental_lookback_hours', 3) }},
            max({{ watermark_col if watermark_col else timestamp_col }})
        )
        from {{ this }}
    )
    {% endif %}
{% endmacro %}
