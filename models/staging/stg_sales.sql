{{ 
  config(
    materialized    = "incremental",
    unique_key      = "key_transaction_id",
    on_schema_change = "sync_all_columns",
    partition_by    = {
      "field": "sale_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by = ["customer_id", "status", "store_id"]
  ) 
}}

with base as (
  select
    date(sale_date) as sale_date,
    cast(customer_id as string) as customer_id,
    cast(product_id  as string) as product_id,
    status,
    store_id,
    concat(
      date(sale_date), '_',
      cast(customer_id as string), '_',
      cast(product_id as string), '_',
      status
    ) as key_transaction_id,
    cast(order_amount  as float64) as revenue_ordered,
    cast(billed_amount as float64) as revenue_billed,
    -- si vous voulez en plus vous assurer qu’en cas de doublons dans le batch, on 
    -- garde toujours la même ligne de référence (par exemple la dernière date/heure)
    row_number() over(
      partition by
        date(sale_date),
        cast(customer_id as string),
        cast(product_id as string),
        status
      order by
        sale_date desc
    ) as rn
  from {{ source('sources_tables','fact_sales') }}
  where sale_date is not null

  {% if is_incremental() %}
    and date(sale_date) > (select max(sale_date) from {{ this }})
  {% endif %}
)

select
  sale_date,
  customer_id,
  key_transaction_id,
  store_id,
  product_id,
  revenue_ordered,
  revenue_billed,
  status
from base
where rn = 1