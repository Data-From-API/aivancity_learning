{{ 
    config(
        materialized="incremental",
        partition_by = {
            "field": "sale_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by = ["customer_id", "status", "store_id"]
        
    ) 
}}

with sales as (
    select
        date(sale_date) as sale_date,
        cast(customer_id as string) as customer_id,
        concat(date(sale_date), '_', customer_id, '_', product_id, '_', status) as key_transaction_id,
        store_id,
        product_id,
        cast(order_amount as float64) as revenue_ordered,
        cast(billed_amount as float64) as revenue_billed,
        status,
        row_number() over(partition by sale_date, customer_id, store_id, product_id order by sale_date asc) as rn
    from {{ source('sources_tables','fact_sales') }}

    where

    {% if is_incremental() %}

     date(sale_date) >= (select max(date(sale_date)) from {{ this }}) and

    {% endif %}

    sale_date is not null
)

select 
    distinct
    sale_date,
    customer_id,
    key_transaction_id,
    store_id,
    product_id,
    revenue_ordered,
    revenue_billed,
    status,
    row_number() over(partition by key_transaction_id) as rn_1
from sales
where rn = 1
qualify rn_1 = 1