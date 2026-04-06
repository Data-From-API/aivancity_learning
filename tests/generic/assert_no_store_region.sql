{% test assert_no_store_region(model, column_name, channel_column) %}

select *
from {{ model }}
where {{ is_valid_store(column_name, channel_column) }} = false

{% endtest %}