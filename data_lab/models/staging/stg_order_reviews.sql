with source as (
    select * from {{ source('raw', 'raw_reviews') }}
),

cleaned as (
    select
        nullIf(trim(review_id), '') as review_id,
        nullIf(trim(order_id), '') as order_id,
        toInt64OrNull(toString(review_score)) as review_score,
        
        nullIf(trim(review_comment_title), '') as review_comment_title,
        nullIf(trim(review_comment_message), '') as review_comment_message,
        
        parseDateTimeBestEffortOrNull(review_creation_date) as review_created_at,
        parseDateTimeBestEffortOrNull(review_answer_timestamp) as review_answered_at
    from source
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by review_id, order_id 
            order by review_answered_at desc
        ) as rn
    from cleaned
    where review_id is not null and order_id is not null
)

select
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_created_at,
    review_answered_at
from deduplicated
where rn = 1