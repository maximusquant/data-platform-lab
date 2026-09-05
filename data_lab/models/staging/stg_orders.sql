-- Active: 1788094161758@@localhost@8123@raw
with source as (
    select * from {{ source('raw', 'raw_orders') }}
),

-- Шаг 2, 3, 4: Стандартизация, каст типов и обработка NULL
cleaned as (
    select
        -- Первичный ключ
        nullIf(trim(order_id), '') as order_id,
        nullIf(trim(customer_id), '') as customer_id,

        -- Стандартизация статусов к нижнему регистру и обработка пустых значений
        lower(trim(coalesce(nullIf(order_status, ''), 'unknown'))) as order_status,

        -- Безопасное приведение строк к DateTime в ClickHouse
        parseDateTimeBestEffortOrNull(order_purchase_timestamp) as order_purchase_at,
        parseDateTimeBestEffortOrNull(order_approved_at) as order_approved_at,
        parseDateTimeBestEffortOrNull(order_delivered_carrier_date) as order_delivered_carrier_at,
        parseDateTimeBestEffortOrNull(order_delivered_customer_date) as order_delivered_customer_at,
        parseDateTimeBestEffortOrNull(order_estimated_delivery_date) as order_estimated_delivery_at
    from source
),

-- Шаг 5, 6: Дедупликация (защита зерна таблицы)
deduplicated as (
    select
        *,
        row_number() over (
            partition by order_id 
            order by order_purchase_at desc, order_approved_at desc
        ) as rn
    from cleaned
    where order_id is not null -- Отсекаем битые битые записи без PK
)

select
    order_id,
    customer_id,
    order_status,
    order_purchase_at,
    order_approved_at,
    order_delivered_carrier_at,
    order_delivered_customer_at,
    order_estimated_delivery_at
from deduplicated
where rn = 1