{{ 
    config(
        materialized="table"
    ) 
}}

select
    store_id,
    store_name,
    channel as store_channel
from {{ source('sources_tables','dim_stores') }}