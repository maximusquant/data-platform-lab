{{ config(
    order_by=['order_id', 'order_item_id']
) }}

with order_items as (
    select * from {{ ref('stg_order_items') }}
    where order_id is not null and order_item_id is not null
)

select
    assumeNotNull(order_id) as order_id,
    assumeNotNull(order_item_id) as order_item_id,
    product_id,
    seller_id,
    shipping_limit_at,
    price,
    freight_value,
    (price + freight_value) as total_item_value
from order_items