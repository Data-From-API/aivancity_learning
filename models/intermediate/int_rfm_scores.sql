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

-- 1) On isole le sous-ensemble "actifs" :
--    R_value <= 365 ET F_value > 0 ET M_value > 0
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

-- 2) On calcule les quintiles (NTILE) sur les actifs uniquement
scores_actifs as (
  select
    customer_id,
    ntile(5) over (order by R_value desc)  as R_score_act,  -- 5 = plus recent (petit R_value)
    ntile(5) over (order by F_value asc)   as F_score_act,  -- 5 = plus frequent (grand F_value)
    ntile(5) over (order by M_value asc)   as M_score_act   -- 5 = plus gros montant (grand M_value)
  from actifs
)

-- 3) On revient sur la table base et on fusionne :
select
  base.customer_id,
  safe_cast(base.R_value as int64) as R_value,

  -- Si le client est dans scores_actifs, on prend le R_score_act, sinon on met 1
  safe_cast(coalesce(scores_actifs.R_score_act, 1) as int64) as R_score,

  base.F_value,

  -- Meme logique pour F_score : si le client n'est pas actif, on force 1
  safe_cast(coalesce(scores_actifs.F_score_act, 1) as int64) as F_score,

  safe_cast(base.M_value as int64) as M_value,

  -- Pour M_score : idem
  safe_cast(coalesce(scores_actifs.M_score_act, 1) as int64) as M_score,

  -- Construction du code RFM X-Y-Z
  concat(
    cast(coalesce(scores_actifs.R_score_act, 1) as string), '-',
    cast(coalesce(scores_actifs.F_score_act, 1) as string), '-',
    cast(coalesce(scores_actifs.M_score_act, 1) as string)
  ) as RFM_code,

  base.snapshot_date

from base
left join scores_actifs
  on base.customer_id = scores_actifs.customer_id
