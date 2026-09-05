with source as (
    select * from {{ source('raw', 'raw_geolocation') }}
),

cleaned as (
    select
        nullIf(trim(toString(geolocation_zip_code_prefix)), '') as geolocation_zip_code_prefix,
        toFloat64OrNull(toString(geolocation_lat)) as geolocation_lat,
        toFloat64OrNull(toString(geolocation_lng)) as geolocation_lng,
        lower(trim(geolocation_city)) as geolocation_city,
        upper(trim(geolocation_state)) as geolocation_state
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by geolocation_zip_code_prefix, geolocation_city, geolocation_state
            order by geolocation_lat, geolocation_lng
        ) as rn
    from cleaned
    where geolocation_zip_code_prefix is not null
)

select
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
from deduplicated
where rn = 1