{{ config(
    order_by='product_id'
) }}

with products as (
    select * from {{ ref('stg_products') }}
    where product_id is not null
),

translations as (
    select * from {{ ref('stg_product_category_translation') }}
)

select
    assumeNotNull(p.product_id) as product_id,
    p.product_category_name,
    coalesce(t.product_category_name_english, p.product_category_name, 'unknown') as category_name_en,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
from products p
left join translations t 
    on p.product_category_name = t.product_category_name