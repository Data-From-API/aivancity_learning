{{ 
    config(
        materialized="table"
    ) 
}}

select distinct
    product_id,
    product_name,
    brand,
    category,
    subcategory,
from {{ source('sources_tables','dim_products') }}