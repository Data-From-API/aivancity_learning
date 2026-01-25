{{
  config(
    materialized   = "incremental",
    unique_key     = ["customer_id", "snapshot_date"],
    partition_by   = {
      "field": "snapshot_date",
      "data_type": "date"
    },
    tags           = ["rfm", "weekly"]
  )
}}

with scores as (
  select
    customer_id,
    R_value,
    R_score,
    F_value,
    F_score,
    M_value,
    M_score,
    RFM_code,
    snapshot_date
  from {{ ref('int_rfm_scores') }}
),

consolidation as 

(select
  customer_id,
  R_value,
  R_score,
  F_value,
  F_score,
  M_value,
  M_score,
  RFM_code,
  snapshot_date,

  -- Attribution du segment_id
  case
    when R_value <= 365
         and R_score = 5 and F_score = 5 and M_score = 5 then 1  -- VIP

    when R_value <= 365
         and (
           (R_score = 5 and F_score = 5 and M_score >= 4)
           or (R_score = 5 and M_score = 5 and F_score >= 4)
           or (F_score = 5 and M_score = 5 and R_score >= 4)
         ) then 2  -- Good Customer

    when R_value <= 365
         and (R_score >= 4 and F_score >= 4 and M_score >= 4) then 3  -- Regular

    when R_value <= 365
         and (R_score in (3,4,5) and (F_score = 1 or M_score = 1)) then 4  -- Expectancy

    when R_value <= 365
         and (R_score in (2,3) and (F_score >= 2 or M_score >= 2)) then 5  -- Opportunist

    when R_value <= 365
         and (R_score in (1,2) and F_score = 1 and M_score = 1) then 6  -- Cold Sensitive

    when R_value <= 365
         and (R_score in (4,5) and F_score = 1 and M_score = 1) then 7  -- Minimalist

    when R_value <= 365
         and (R_score = 5 and F_score = 1 and M_score = 1) then 8  -- New

    when R_value > 365 then 9  -- Inactive

    else 3  -- Fallback
  end as segment_id

from scores)

-- Jointure avec le seed pour récupérer le segment_name
select
  c.*,
  s.segment_name
from consolidation c
left join {{ ref('rfm_segments') }} s
  on c.segment_id = s.segment_id