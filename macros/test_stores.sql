{% macro is_valid_store(store_city, normalized_store_channel) %}
    case
        when {{ store_city }} is null 
         and {{ normalized_store_channel }} = 'Store' 
        then false
        else true
    end
{% endmacro %}