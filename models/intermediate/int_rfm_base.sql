{{
  config(
    materialized = "ephemeral",
    tags         = ["rfm", "weekly"]
  )
}}

-- On utilise CURRENT_DATE() pour le snapshot_date
{% set snapshot_date = "CURRENT_DATE()" %}

-- 1) Extraction de la date de derniere vente (R) sur les 3 dernieres annees
with historical_sales as (
  select
    customer_id,
    cast(sale_date as date) as sale_date,
    revenue_billed
  from {{ ref('stg_sales') }}
  where
    revenue_billed > 0
    and cast(sale_date as date)
        between date_sub({{ snapshot_date }}, interval 3 year)
            and {{ snapshot_date }}
),

last_purchase as (
  select
    customer_id,
    max(sale_date) as last_sale_date
  from historical_sales
  group by customer_id
),

-- 2) Calcul de F_value et M_value sur les 12 mois precedents snapshot_date
recent_sales_12m as (
  select
    customer_id,
    key_transaction_id,
    revenue_billed,
    cast(sale_date as date) as sale_date
  from {{ ref('stg_sales') }}
  where
    revenue_billed > 0
    and cast(sale_date as date)
        between date_sub({{ snapshot_date }}, interval 12 month)
            and {{ snapshot_date }}
),

rfm_12m as (
  select
    customer_id,
    count(distinct key_transaction_id) as F_value,
    sum(revenue_billed)           as M_value
  from recent_sales_12m
  group by customer_id
),

-- 3) Liste exhaustive de tous les clients
all_customers as (
  select distinct customer_id
  from {{ ref('stg_customers') }}
)

select
  all_customers.customer_id,

  -- Si le client n'a jamais achete sur les 3 dernieres annees, last_sale_date = NULL
  last_purchase.last_sale_date,

  -- R_value en jours ; si null, on met artificiellement un R_value tres eleve (ici 9999)
  cast(
    date_diff(
    {{ snapshot_date }},
    coalesce(last_purchase.last_sale_date, date_sub({{ snapshot_date }}, interval 100 year)),
    day
  ) as int64) as R_value,

  -- F_value = 0 si pas d'achat dans les 12 mois
  cast(coalesce(rfm_12m.F_value, 0) as int64) as F_value,

  -- M_value = 0 si pas d'achat dans les 12 mois
  cast(coalesce(rfm_12m.M_value, 0) as int64) as M_value,

  {{ snapshot_date }} as snapshot_date

from all_customers
left join last_purchase
  on all_customers.customer_id = last_purchase.customer_id
left join rfm_12m
  on all_customers.customer_id = rfm_12m.customer_id
