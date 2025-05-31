{{ 
  config(
    materialized   = "incremental",
    unique_key     = ["customer_id", "snapshot_date"],
    partition_by   = {
      "field": "snapshot_date",
      "data_type": "date"
    }
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

  -- 1) Attribution du segment_id
  case
    -- (a) Clients strictement “actifs” (R_value ≤ 365 et F_value > 0)
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

    -- (b) Tous les clients “inactifs” (R_value > 365) tombent ici,
    --     quel que soit leur F_score/M_score. Ils ne rentrent pas dans
    --     les conditions “actifs” précédentes, donc finiront en 9
    when R_value > 365 then 9  -- Inactive

    -- (c) Fallback : en pratique, ne devrait jamais être utilisé,
    --     mais on le laisse sur “Regular” pour éviter tout NULL
    else 3
  end as segment_id,

  -- 2) Attribution du segment_name
  case
    when R_value <= 365
         and R_score = 5 and F_score = 5 and M_score = 5 then 'VIP'
    when R_value <= 365
         and (
           (R_score = 5 and F_score = 5 and M_score >= 4)
           or (R_score = 5 and M_score = 5 and F_score >= 4)
           or (F_score = 5 and M_score = 5 and R_score >= 4)
         ) then 'Good Customer'
    when R_value <= 365
         and (R_score >= 4 and F_score >= 4 and M_score >= 4) then 'Regular'
    when R_value <= 365
         and (R_score in (3,4,5) and (F_score = 1 or M_score = 1)) then 'Expectancy'
    when R_value <= 365
         and (R_score in (2,3) and (F_score >= 2 or M_score >= 2)) then 'Opportunist'
    when R_value <= 365
         and (R_score in (1,2) and F_score = 1 and M_score = 1) then 'Cold Sensitive'
    when R_value <= 365
         and (R_score in (4,5) and F_score = 1 and M_score = 1) then 'Minimalist'
    when R_value <= 365
         and (R_score = 5 and F_score = 1 and M_score = 1) then 'New'

    when R_value > 365 then 'Inactive'

    else 'Regular'
  end as segment_name

from scores)

select * from consolidation