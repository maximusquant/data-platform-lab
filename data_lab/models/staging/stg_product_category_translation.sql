with source as (
    select * from {{ source('raw', 'raw_category_translation') }}
),

cleaned as (
    select
        lower(trim(nullIf(product_category_name, ''))) as product_category_name,
        lower(trim(nullIf(product_category_name_english, ''))) as product_category_name_english
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by product_category_name
            order by product_category_name_english
        ) as rn
    from cleaned
    where product_category_name is not null
)

select
    product_category_name,
    product_category_name_english
from deduplicated
where rn = 1