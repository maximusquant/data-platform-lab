{{ config(
    order_by=['first_purchase_month', 'cohort_month']
) }}

with orders_with_customers as (
    select
        c.customer_unique_id,
        o.order_id,
        toStartOfMonth(o.order_purchase_at) as order_month,
        o.total_payment_value
    from {{ ref('fact_orders') }} o
    inner join {{ ref('stg_customer') }} c on o.customer_id = c.customer_id
    where o.order_status = 'delivered' 
      and o.order_purchase_at is not null
),

customer_first_purchase as (
    select
        customer_unique_id,
        min(order_month) as first_purchase_month
    from orders_with_customers
    group by customer_unique_id
),

cohort_data as (
    select
        o.customer_unique_id,
        f.first_purchase_month,
        o.order_month as cohort_month,
        dateDiff('month', f.first_purchase_month, o.order_month) as month_number,
        o.total_payment_value
    from orders_with_customers o
    inner join customer_first_purchase f on o.customer_unique_id = f.customer_unique_id
)

select
    assumeNotNull(first_purchase_month) as first_purchase_month,
    assumeNotNull(cohort_month) as cohort_month,
    month_number,
    count(distinct customer_unique_id) as active_customers,
    round(sum(total_payment_value), 2) as cohort_revenue,
    round(sum(total_payment_value) / count(distinct customer_unique_id), 2) as ltv_per_customer
from cohort_data
group by first_purchase_month, cohort_month, month_number