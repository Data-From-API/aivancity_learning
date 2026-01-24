{% snapshot snap_customers %}

{{
  config(
    target_schema = 'snapshots',
    unique_key    = 'customer_id',
    strategy      = 'check',
    check_cols    = ['loyalty_level', 'is_loyalty_member']
  )
}}

select
    customer_id,
    first_name,
    last_name,
    gender,
    is_loyalty_member,
    loyalty_level,
    date(signup_date) as signup_date
from {{ source('sources_tables', 'dim_customers') }}

{% endsnapshot %}
