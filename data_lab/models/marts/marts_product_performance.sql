{{ config(
    order_by='category_name_en'
) }}

select
    assumeNotNull(p.category_name_en) as category_name_en,
    count(distinct i.order_id) as total_orders_count,
    count(i.order_item_id) as total_items_sold,
    round(sum(i.price), 2) as total_gross_revenue,
    round(sum(i.freight_value), 2) as total_freight_value,
    round(avg(i.price), 2) as avg_item_price,
    round(avg(o.review_score), 2) as avg_category_review_score
from {{ ref('fact_order_items') }} i
inner join {{ ref('dim_products') }} p on i.product_id = p.product_id
inner join {{ ref('fact_orders') }} o on i.order_id = o.order_id
where o.order_status = 'delivered'
group by category_name_en