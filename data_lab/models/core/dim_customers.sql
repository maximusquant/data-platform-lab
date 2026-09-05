{{ config(
    order_by='customer_unique_id'
) }}

with customers as (
    select * from {{ ref('stg_customer') }}
    where customer_unique_id is not null
)

select
    assumeNotNull(customer_unique_id) as customer_unique_id,
    any(customer_zip_code_prefix) as customer_zip_code_prefix,
    any(customer_city) as customer_city,
    any(customer_state) as customer_state,
    count(distinct customer_id) as total_orders_count
from customers
group by customer_unique_id