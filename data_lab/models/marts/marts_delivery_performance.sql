{{ config(
    order_by='customer_state'
) }}

select
    assumeNotNull(c.customer_state) as customer_state,
    any(c.customer_city) as sample_city,
    count(distinct o.order_id) as total_orders,
    round(sum(o.total_payment_value), 2) as total_state_revenue,
    
    round(avg(dateDiff('day', o.order_purchase_at, o.order_delivered_customer_at)), 1) as avg_actual_delivery_days,
    round(avg(dateDiff('day', o.order_purchase_at, o.order_estimated_delivery_at)), 1) as avg_estimated_delivery_days,
    
    round(countIf(o.order_delivered_customer_at > o.order_estimated_delivery_at) * 100.0 / count(o.order_id), 2) as late_delivery_pct
from {{ ref('fact_orders') }} o
inner join {{ ref('stg_customer') }} c on o.customer_id = c.customer_id
where o.order_status = 'delivered' 
  and o.order_purchase_at is not null 
  and o.order_delivered_customer_at is not null
group by customer_state