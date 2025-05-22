{{ 
    config(
        materialized="table"
    ) 
}}

select distinct
    store_id,
    store_name,
    channel as store_channel
from {{ source('sources_tables','dim_stores') }}