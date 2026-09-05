with source as (
    select * from {{ source('raw', 'raw_order_items') }}
),

cleaned as (
    select
        nullIf(trim(order_id), '') as order_id,
        toInt64OrNull(toString(order_item_id)) as order_item_id,
        nullIf(trim(product_id), '') as product_id,
        nullIf(trim(seller_id), '') as seller_id,
        
        parseDateTimeBestEffortOrNull(shipping_limit_date) as shipping_limit_at,
        toFloat64OrNull(toString(price)) as price,
        toFloat64OrNull(toString(freight_value)) as freight_value
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by order_id, order_item_id 
            order by shipping_limit_at desc
        ) as rn
    from cleaned
    where order_id is not null and order_item_id is not null
)

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_at,
    price,
    freight_value
from deduplicated
where rn = 1