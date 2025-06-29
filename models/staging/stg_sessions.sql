{{ 
  config(
    materialized    = "incremental",
    unique_key      = "day",
    on_schema_change = "sync_all_columns",
    partition_by    = {
      "field": "date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by = ["device_type"]
  ) 
}}

select
    session_date as date,
    device_type,
    sum(cast(nb_sessions as int64)) as sessions
from {{ source('sources_tables','fact_sessions') }}
where session_date is not null

{% if is_incremental() %}
  and date(session_date) > (select max(session_date) from {{ this }})
{% endif %}
group by all