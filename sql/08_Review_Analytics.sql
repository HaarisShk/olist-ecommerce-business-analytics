/*
==========================================================
Query 1: Overall Customer Satisfaction

Business Question:
How satisfied are customers with their overall
shopping experience?

Business Logic:
- Uses customer review ratings.
- Calculates overall satisfaction metrics.
- Measures the proportion of highly satisfied
  and highly dissatisfied customers.
==========================================================
*/

SELECT

    COUNT(*) AS total_reviews,

    ROUND
    (
        AVG(review_score * 1.0),
        2
    ) AS average_rating,

    SUM
    (
        CASE
            WHEN review_score = 5
            THEN 1
            ELSE 0
        END
    ) AS five_star_reviews,

    SUM
    (
        CASE
            WHEN review_score = 1
            THEN 1
            ELSE 0
        END
    ) AS one_star_reviews,

    ROUND
    (
        SUM
        (
            CASE
                WHEN review_score = 5
                THEN 1
                ELSE 0
            END
        ) * 100.0 /
        COUNT(*),
        2
    ) AS five_star_review_percentage,

    ROUND
    (
        SUM
        (
            CASE
                WHEN review_score = 1
                THEN 1
                ELSE 0
            END
        ) * 100.0 /
        COUNT(*),
        2
    ) AS one_star_review_percentage

FROM order_reviews;



/*
==========================================================
Query 2: Product Category Satisfaction

Business Question:
Which product categories receive the highest
and lowest customer ratings?

Business Logic:
- Uses delivered orders with customer reviews.
- Calculates the average review rating for
  each product category.
- Includes only categories with at least
  100 reviews for meaningful comparison.
==========================================================
*/

SELECT

    v.product_category,

    COUNT(r.review_id) AS total_reviews,

    ROUND
    (
        AVG(r.review_score * 1.0),
        2
    ) AS average_rating,

    DENSE_RANK() OVER
    (
        ORDER BY
        ROUND(AVG(r.review_score * 1.0),2) DESC
    ) AS satisfaction_rank

FROM vw_item_details v

INNER JOIN order_reviews r
    ON v.order_id = r.order_id

GROUP BY
    v.product_category

HAVING COUNT(r.review_id) >= 100

ORDER BY
    satisfaction_rank,
    total_reviews DESC;




/*
==========================================================
Query 3: State-wise Customer Satisfaction

Business Question:
Which customer states report the highest
and lowest customer satisfaction ratings?

Business Logic:
- Uses customer reviews for delivered orders.
- Calculates the average review rating by
  customer state.
- Includes states with at least 100 reviews
  for meaningful comparison.
==========================================================
*/

SELECT

    c.customer_state,

    COUNT(r.review_id) AS total_reviews,

    ROUND
    (
        AVG(r.review_score * 1.0),
        2
    ) AS average_rating,

    DENSE_RANK() OVER
    (
        ORDER BY
        ROUND(AVG(r.review_score * 1.0),2) DESC
    ) AS satisfaction_rank

FROM orders o

INNER JOIN customers c
    ON o.customer_id = c.customer_id

INNER JOIN order_reviews r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'

GROUP BY
    c.customer_state

HAVING COUNT(r.review_id) >= 100

ORDER BY
    satisfaction_rank,
    total_reviews DESC;




/*
==========================================================
Query 4: Impact of Delivery Delays on Customer Ratings

Business Question:
Do delayed deliveries result in lower
customer satisfaction?

Business Logic:
- Considers only delivered orders.
- Classifies each order as On-Time or Delayed.
- Compares customer review ratings between
  the two delivery groups.
==========================================================
*/

SELECT

    CASE
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
        THEN 'On-Time'

        ELSE 'Delayed'
    END AS delivery_status,

    COUNT(*) AS total_orders,

    ROUND
    (
        AVG(r.review_score * 1.0),
        2
    ) AS average_rating,

    ROUND
    (
        SUM
        (
            CASE
                WHEN r.review_score = 5
                THEN 1
                ELSE 0
            END
        ) * 100.0 /
        COUNT(*),
        2
    ) AS five_star_review_percentage,

    ROUND
    (
        SUM
        (
            CASE
                WHEN r.review_score = 1
                THEN 1
                ELSE 0
            END
        ) * 100.0 /
        COUNT(*),
        2
    ) AS one_star_review_percentage

FROM orders o

INNER JOIN order_reviews r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'

GROUP BY

    CASE
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
        THEN 'On-Time'

        ELSE 'Delayed'
    END

ORDER BY average_rating DESC;