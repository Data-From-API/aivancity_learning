
select
--Transaction Info
    sale_date,
    key_transaction_id,
    sales.store_id,
    store.store_name,
    {{ normalize_channel('store_channel') }} as store_channel,
    {{ is_valid_store('store.city', 'store_channel') }} as is_valid_store_flag,
    store.city as store_city,
    store.region as store_region,
    revenue_ordered,
    revenue_billed,
-- Product Info
    product.product_id,
    product.product_name,
    product.brand as product_brand,
    product.category as product_category,
    product.subcategory as product_subcategory,
-- Customer Info
    cast(sales.customer_id as string) as customer_id,
    customer.fullname as customer_fullname,
    {{ normalize_gender('customer.gender') }} as customer_gender,
    customer.is_loyalty_member as is_customer_loyal,
    coalesce(customer.loyalty_level, 'No Loyalty') as customer_loyalty_level,
    customer.signup_date as customer_loyalty_subscription_date,
    first_value(sale_date) over (partition by sales.customer_id order by sale_date asc) as first_purchase_date,
    last_value(sale_date) over (partition by sales.customer_id order by sale_date desc) as last_purchase_date,
from {{ ref('stg_sales') }} sales
left join {{ ref('stg_products') }} product on product.product_id = sales.product_id
left join {{ ref('stg_customers') }} customer on customer.customer_id = sales.customer_id
left join {{ ref('stg_store') }} store on store.store_id = sales.store_id