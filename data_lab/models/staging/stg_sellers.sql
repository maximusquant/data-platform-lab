with source as (
    select * from {{ source('raw', 'raw_sellers') }}
),

cleaned as (
    select
        nullIf(trim(seller_id), '') as seller_id,
        nullIf(trim(toString(seller_zip_code_prefix)), '') as seller_zip_code_prefix,
        lower(trim(seller_city)) as seller_city,
        upper(trim(seller_state)) as seller_state
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by seller_id 
            order by seller_state
        ) as rn
    from cleaned
    where seller_id is not null
)

select
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
from deduplicated
where rn = 1