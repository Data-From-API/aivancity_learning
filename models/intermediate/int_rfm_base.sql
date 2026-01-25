{{
  config(
    materialized = "ephemeral",
    tags         = ["rfm", "weekly"]
  )
}}

-- On utilise CURRENT_DATE() pour le snapshot_date
{% set snapshot_date = "CURRENT_DATE()" %}

-- 1) Extraction de la date de dernière vente (R) sur les 3 dernières années
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

-- 2) Calcul de F_value et M_value sur les 12 mois précédents snapshot_date
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
  a.customer_id,

  -- Si le client n’a jamais acheté sur les 3 dernières années, last_sale_date = NULL
  lp.last_sale_date,

  -- R_value en jours ; si null, on met artificiellement un R_value très élevé (ici 9999)
  cast(
    date_diff(
    {{ snapshot_date }},
    coalesce(lp.last_sale_date, date_sub({{ snapshot_date }}, interval 100 year)),
    day
  ) as int64) as R_value,

  -- F_value = 0 si pas d’achat dans les 12 mois
  cast(coalesce(r12.F_value, 0) as int64) as F_value,

  -- M_value = 0 si pas d’achat dans les 12 mois
  cast(coalesce(r12.M_value, 0) as int64) as M_value,

  {{ snapshot_date }} as snapshot_date

from all_customers a
left join last_purchase lp
  on a.customer_id = lp.customer_id
left join rfm_12m r12
  on a.customer_id = r12.customer_id