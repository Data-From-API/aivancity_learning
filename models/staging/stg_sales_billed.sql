{{ 
  config(
    materialized = "view"
  ) 
}}

-- Ne garder QUE les ventes facturées positif sur 12 mois

with filtered as (

  select
    customer_id,
    cast(sale_date as date) as sale_date,
    key_transaction_id,
    revenue_billed
  from {{ ref('stg_sales')}}
  where
    revenue_billed > 0
    and cast(sale_date as date)
        between date_sub((date(current_date)), interval 12 month)
            and date(current_date)

)

select * from filtered