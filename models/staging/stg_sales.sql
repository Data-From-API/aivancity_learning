{{ 
    config(
        materialized="table",
        partition_by = {
            "field": "sale_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by = ["customer_id", "status", "store_id"]
    ) 
}}

select
    date(sale_date) as sale_date,
    customer_id,
    concat(date(sale_date), '_', customer_id, '_', product_id) as key_transaction_id,
    store_id,
    product_id,
    cast(order_amount as float64) as revenue_ordered,
    cast(billed_amount as float64) as revenue_billed,
    status
from {{ source('sources_tables','fact_sales') }}
where sale_date is not null