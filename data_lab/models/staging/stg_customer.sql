with source as (
    select * from {{ source('raw', 'raw_customers') }}
),

cleaned as (
    select
        nullIf(trim(customer_id), '') as customer_id,
        nullIf(trim(customer_unique_id), '') as customer_unique_id,
        
        -- Почтовый индекс фиксируем как строку
        nullIf(trim(toString(customer_zip_code_prefix)), '') as customer_zip_code_prefix,
        
        -- Город к нижнему регистру и очистка от краев
        lower(trim(customer_city)) as customer_city,
        
        -- Код штата (SP, RJ и т.д.) всегда в верхнем регистре
        upper(trim(customer_state)) as customer_state
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by customer_id 
            order by customer_unique_id
        ) as rn
    from cleaned
    where customer_id is not null
)

select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
from deduplicated
where rn = 1