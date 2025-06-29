{{ 
    config(
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
    case 
        when date(sale_date) = date(first_purchase_date) 
        then 'New Customer' 
        else 'Returning Customer' 
    end as customer_type,
    product_category,
    product_subcategory,
    customer_loyalty_level,
    customer_gender,
    store_city,
    store_region,
    store_channel,
    count(product_id) as total_product_sold,
    count(distinct product_id) as nb_distinct_product_sold,
    sum(revenue_ordered) as revenue_ordered,
    sum(revenue_billed) as revenue_billed,
    count(distinct key_transaction_id) as nb_transactions,
    count(distinct customer_id) as nb_customer,
from {{ ref('int_sales') }}
group by all