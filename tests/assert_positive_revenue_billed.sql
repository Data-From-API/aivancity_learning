-- This test returns rows where revenue_billed is negative in stg_sales.
-- If any rows are returned, the test fails.

select
    key_transaction_id,
    customer_id,
    sale_date,
    revenue_billed
from {{ ref('stg_sales') }}
where revenue_billed < 0
