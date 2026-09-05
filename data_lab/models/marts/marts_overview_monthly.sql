{{ config(
    order_by='sales_month'
) }}

with monthly_base as (
    select
        toStartOfMonth(o.order_purchase_at) as sales_month,
        count(distinct o.order_id) as total_orders,
        count(distinct c.customer_unique_id) as unique_customers,
        sum(o.total_payment_value) as total_revenue,
        avg(o.total_payment_value) as average_order_value,
        avg(o.review_score) as avg_review_score
    from {{ ref('fact_orders') }} o
    left join {{ ref('stg_customer') }} c on o.customer_id = c.customer_id
    where o.order_status = 'delivered' and o.order_purchase_at is not null
    group by sales_month
)

select
    assumeNotNull(sales_month) as sales_month,
    total_orders,
    unique_customers,
    round(total_revenue, 2) as total_revenue,
    round(average_order_value, 2) as average_order_value,
    round(avg_review_score, 2) as avg_review_score,
    
    round(lagInFrame(total_revenue, 1) over (order by sales_month), 2) as prev_month_revenue,
    round((total_revenue - lagInFrame(total_revenue, 1) over (order by sales_month)) 
          / nullIf(lagInFrame(total_revenue, 1) over (order by sales_month), 0) * 100, 2) as revenue_mom_growth_pct
from monthly_base