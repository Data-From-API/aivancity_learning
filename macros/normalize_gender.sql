{% macro normalize_gender(column_name) %}
    case
        when {{ column_name }} = 'male' then 'M'
        when {{ column_name }} = 'female' then 'F'
        else 'Not Defined'
    end
{% endmacro %}
