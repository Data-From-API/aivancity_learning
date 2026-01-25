{{
  config(
    materialized = "table",
    tags         = ["rfm", "weekly"]
  )
}}

with base as (
  select *
  from {{ ref('int_rfm_base') }}
),

-- 1) On isole le sous-ensemble “actifs” :
--    R_value ≤ 365 ET F_value > 0 ET M_value > 0
actifs as (
  select
    customer_id,
    cast(R_value as int64) as R_value,
    cast(F_value as int64) as F_value,
    cast(M_value as int64) as M_value
  from base
  where R_value <= 365
    and F_value > 0
    and M_value > 0
),

-- 2) On calcule les quintiles (NTILE) SUR CE SEULEMENT
scores_actifs as (
  select
    customer_id,
    ntile(5) over (order by R_value asc)   as R_score_act,
    ntile(5) over (order by F_value desc)  as F_score_act,
    ntile(5) over (order by M_value desc)  as M_score_act
  from actifs
)

-- 3) On revient ensuite sur la table “base” et on fusionne :
select
  b.customer_id,
  safe_cast(b.R_value as int64) as R_value,

  -- Si le client est dans “scores_actifs”, on prend le R_score_act, sinon on met 1
  safe_cast(coalesce(sa.R_score_act, 1) as int64) as R_score,

  b.F_value,

  -- Même logique pour F_score : si le client n’est pas actif, on force 1
  safe_cast(coalesce(sa.F_score_act, 1) as int64) as F_score,

  safe_cast(b.M_value as int64) as M_value,

  -- Pour M_score : idem
  safe_cast(coalesce(sa.M_score_act, 1) as int64) as M_score,

  -- Construction du code RFM “X-Y-Z”
  concat(
    cast(coalesce(sa.R_score_act, 1) as string), '-',
    cast(coalesce(sa.F_score_act, 1) as string), '-',
    cast(coalesce(sa.M_score_act, 1) as string)
  ) as RFM_code,

  b.snapshot_date

from base b
left join scores_actifs sa
  on b.customer_id = sa.customer_id