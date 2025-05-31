
select
--Transaction Info
    sale_date,
    key_transaction_id,
    sales.store_id,
    store.store_name,
    case 
        when store_channel = 'boutique' then 'Store'
        when store_channel = 'ecommerce' then 'eStore'
        when store_channel = 'click_collect' then 'eStore'
        else 'Not Defined' 
    end as store_channel,
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
    sales.customer_id,
    customer.fullname as customer_fullname,
    case 
        when customer.gender = 'male' then 'M'
        when customer.gender = 'female' then 'F'
        else 'Not Defined'
    end as customer_gender,
    customer.is_loyalty_member as is_customer_loyal,
    coalesce(customer.loyalty_level, 'No Loyalty') as customer_loyalty_level,
    customer.signup_date as customer_loyalty_subscription_date,
    first_value(sale_date) over (partition by sales.customer_id order by sale_date asc) as first_purchase_date,
    last_value(sale_date) over (partition by sales.customer_id order by sale_date desc) as last_purchase_date,
from {{ ref('stg_sales') }} sales
left join {{ ref('stg_products') }} product on product.product_id = sales.product_id
left join {{ ref('stg_customers') }} customer on customer.customer_id = sales.customer_id
left join {{ ref('stg_store') }} store on store.store_id = sales.store_id