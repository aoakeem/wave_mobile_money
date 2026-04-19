{% macro incremental_lookback(timestamp_col) %}
    {% if is_incremental() %}
    where {{ timestamp_col }} >= (
        select dateadd(
            hour,
            -{{ var('incremental_lookback_hours', 3) }},
            max({{ timestamp_col }})
        )
        from {{ this }}
    )
    {% endif %}
{% endmacro %}
