{{ config(
    order_by='order_id'
) }}

with orders as (
    select * from {{ ref('stg_orders') }}
    where order_id is not null
),

payments_agg as (
    select
        order_id,
        sum(payment_value) as total_payment_value,
        max(payment_installments) as max_installments,
        count(payment_sequential) as payment_installments_count
    from {{ ref('stg_payments') }}
    group by order_id
),

reviews as (
    select
        order_id,
        any(review_score) as review_score,
        any(review_created_at) as review_created_at
    from {{ ref('stg_order_reviews') }}
    group by order_id
)

select
    assumeNotNull(o.order_id) as order_id,
    assumeNotNull(o.customer_id) as customer_id,
    o.order_status,
    o.order_purchase_at,
    o.order_approved_at,
    o.order_delivered_carrier_at,
    o.order_delivered_customer_at,
    o.order_estimated_delivery_at,
    coalesce(p.total_payment_value, 0) as total_payment_value,
    coalesce(p.max_installments, 1) as max_installments,
    r.review_score,
    r.review_created_at
from orders o
left join payments_agg p on o.order_id = p.order_id
left join reviews r on o.order_id = r.order_id