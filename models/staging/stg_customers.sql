{{ 
    config(
        materialized="table",
        partition_by = {
            "field": "signup_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by = ["loyalty_level"]
    ) 
}}

select distinct
    customer_id,
    first_name,
    last_name,
    concat(first_name, ' ', last_name) as fullname,
    gender,
    is_loyalty_member,
    loyalty_level,
    date(signup_date) as signup_date
from {{ source('sources_tables','dim_customers') }}