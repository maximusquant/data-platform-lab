with source as (
    select * from {{ source('raw', 'raw_products') }}
),

cleaned as (
    select
        nullIf(trim(product_id), '') as product_id,
        nullIf(trim(product_category_name), '') as product_category_name,
        
        -- Числовые характеристики с подстраховкой от аномалий
        toFloat64OrNull(toString(product_name_lenght)) as product_name_length,
        toFloat64OrNull(toString(product_description_lenght)) as product_description_length,
        toFloat64OrNull(toString(product_photos_qty)) as product_photos_qty,
        toFloat64OrNull(toString(product_weight_g)) as product_weight_g,
        toFloat64OrNull(toString(product_length_cm)) as product_length_cm,
        toFloat64OrNull(toString(product_height_cm)) as product_height_cm,
        toFloat64OrNull(toString(product_width_cm)) as product_width_cm
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by product_id 
            order by product_category_name
        ) as rn
    from cleaned
    where product_id is not null
)

select
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
from deduplicated
where rn = 1