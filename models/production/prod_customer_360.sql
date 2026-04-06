{{
  config(
    materialized   = "table",
    cluster_by     = ["segment_name", "customer_loyalty_level"],
    tags           = ["rfm", "weekly"]
  )
}}

with rfm as (
  select
    customer_id,
    R_value,
    R_score,
    F_value,
    F_score,
    M_value,
    M_score,
    RFM_code,
    segment_id,
    segment_name,
    snapshot_date
  from {{ ref('final_rfm_segmentation') }}
  where snapshot_date = (select max(snapshot_date) from {{ ref('final_rfm_segmentation') }})
),

customer_profile as (
  select
    customer_id,
    customer_gender,
    is_loyalty_member,
    loyalty_level,
    signup_date,
    first_purchase_date,
    last_purchase_date
  from {{ ref('int_customers') }}
),

sales_last_12m as (
  select *
  from {{ ref('int_sales') }}
  where sale_date >= date_sub(current_date(), interval 12 month)
),

sales_agg as (
  select
    cast(customer_id as string) as customer_id,
    sum(revenue_billed) as total_revenue_billed,
    sum(revenue_ordered) as total_revenue_ordered,
    count(distinct key_transaction_id) as total_transactions,
    count(distinct product_id) as nb_distinct_products,
    count(distinct product_category) as nb_categories,
    sum(revenue_billed) / nullif(count(distinct key_transaction_id), 0) as avg_basket,
    sum(revenue_ordered) - sum(revenue_billed) as total_unbilled_amount,
  from sales_last_12m
  group by customer_id
),

preferred_category as (
  select
    cast(customer_id as string) as customer_id,
    product_category as preferred_category
  from (
    select
      customer_id,
      product_category,
      row_number() over (
        partition by customer_id
        order by sum(revenue_billed) desc
      ) as rn
    from sales_last_12m
    group by customer_id, product_category
  )
  where rn = 1
),

preferred_channel as (
  select
    cast(customer_id as string) as customer_id,
    store_channel as preferred_channel
  from (
    select
      customer_id,
      store_channel,
      row_number() over (
        partition by customer_id
        order by count(distinct key_transaction_id) desc
      ) as rn
    from sales_last_12m
    group by customer_id, store_channel
  )
  where rn = 1
),

preferred_region as (
  select
    cast(customer_id as string) as customer_id,
    store_region as preferred_region
  from (
    select
      customer_id,
      store_region,
      row_number() over (
        partition by customer_id
        order by count(distinct key_transaction_id) desc
      ) as rn
    from sales_last_12m
    where store_region is not null and store_region != ''
    group by customer_id, store_region
  )
  where rn = 1
)

select
  -- Customer profile
  rfm.customer_id,
  customer_profile.customer_gender,
  coalesce(customer_profile.loyalty_level, 'No Loyalty') as customer_loyalty_level,
  customer_profile.is_loyalty_member,
  customer_profile.signup_date,
  customer_profile.first_purchase_date,
  customer_profile.last_purchase_date,

  -- RFM scores & segment
  rfm.R_value,
  rfm.R_score,
  rfm.F_value,
  rfm.F_score,
  rfm.M_value,
  rfm.M_score,
  rfm.RFM_code,
  rfm.segment_id,
  rfm.segment_name,

  -- Sales metrics
  coalesce(sales_agg.total_revenue_billed, 0) as total_revenue_billed,
  coalesce(sales_agg.total_revenue_ordered, 0) as total_revenue_ordered,
  coalesce(sales_agg.total_transactions, 0) as total_transactions,
  coalesce(sales_agg.nb_distinct_products, 0) as nb_distinct_products,
  coalesce(sales_agg.nb_categories, 0) as nb_categories,
  coalesce(sales_agg.avg_basket, 0) as avg_basket,
  coalesce(sales_agg.total_unbilled_amount, 0) as total_unbilled_amount,

  -- Preferences
  preferred_category.preferred_category,
  preferred_channel.preferred_channel,
  preferred_region.preferred_region,

  -- Metadata
  rfm.snapshot_date

from rfm
left join customer_profile on customer_profile.customer_id = rfm.customer_id
left join sales_agg on sales_agg.customer_id = rfm.customer_id
left join preferred_category on preferred_category.customer_id = rfm.customer_id
left join preferred_channel on preferred_channel.customer_id = rfm.customer_id
left join preferred_region on preferred_region.customer_id = rfm.customer_id
