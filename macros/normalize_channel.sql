{% macro normalize_channel(column_name) %}
    case
        when {{ column_name }} = 'boutique' then 'Store'
        when {{ column_name }} = 'ecommerce' then 'eStore'
        when {{ column_name }} = 'click_collect' then 'eStore'
        else 'Not Defined'
    end
{% endmacro %}
