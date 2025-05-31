with customer_data as (
    select 
        customer_id,
        gender as customer_gender,
        is_loyalty_member,
        coalesce(loyalty_level, 'No loyalty Level') as loyalty_level,
        signup_date,
    from {{ ref('stg_customers') }}
),

orders as (
    select
        customer_id,
        max(sale_date) as last_purchase_date,
        min(sale_date) as first_purchase_date,
    from {{ ref('stg_sales') }}
    group by customer_id
)

select
    customer_data.customer_id,
    customer_gender,
    is_loyalty_member,
    loyalty_level,
    signup_date,
    orders.last_purchase_date,
    orders.first_purchase_date,
from customer_data
left join orders on orders.customer_id = customer_data.customer_id