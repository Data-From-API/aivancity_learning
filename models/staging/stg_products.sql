{{ 
    config(
        materialized="table"
    ) 
}}

select 
    product_id,
    product_name,
    brand,
    category,
    subcategory,
from {{ source('sources_tables','dim_products') }}