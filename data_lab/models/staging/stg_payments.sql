with source as (
    select * from {{ source('raw', 'raw_payments') }}
),

cleaned as (
    select
        nullIf(trim(order_id), '') as order_id,
        toInt64OrNull(toString(payment_sequential)) as payment_sequential,
        lower(trim(nullIf(payment_type, ''))) as payment_type,
        toInt64OrNull(toString(payment_installments)) as payment_installments,
        toFloat64OrNull(toString(payment_value)) as payment_value
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by order_id, payment_sequential 
            order by payment_value desc
        ) as rn
    from cleaned
    where order_id is not null
)

select
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
from deduplicated
where rn = 1