-- This test returns rows where sale_date is in the future.
-- If any rows are returned, the test fails.

select
    key_transaction_id,
    customer_id,
    sale_date
from {{ ref('stg_sales') }}
where sale_date > current_date()
