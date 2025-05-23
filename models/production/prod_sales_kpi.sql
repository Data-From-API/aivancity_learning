{{ 
    config(
        materialized="table",
        partition_by = {
            "field": "sale_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by = ["customer_loyalty_level", "product_category"]
    ) 
}}

select
    sale_date,
    product_category,
    product_subcategory,
    customer_loyalty_level,
    customer_gender,
    store_city,
    store_region,
    count(product_id) as total_product_sold,
    count(distinct product_id) as nb_distinct_product_sold,
    sum(revenue_ordered) as revenue_ordered,
    sum(revenue_billed) as revenue_billed,
    count(distinct key_transaction_id) as nb_transactions,
    count(distinct customer_id) as nb_customer,
from {{ ref('int_sales') }}
group by all