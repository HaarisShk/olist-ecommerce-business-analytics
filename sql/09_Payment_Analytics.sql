/*==============================================================
                 PAYMENT ANALYTICS

Description : Analyze customer payment behavior, installment
              usage and payment preferences across order
              values and customer states.

==============================================================*/


/*==============================================================
PAYMENT METHOD ANALYSIS

Objective:
Evaluate payment method usage by analyzing order volume,
revenue contribution and average payment value across
different payment methods.

==============================================================*/

SELECT

    payment_type,

    COUNT(DISTINCT order_id) AS total_orders,
	CAST(ROUND(
    COUNT(DISTINCT order_id) * 100.0 /
    SUM(COUNT(DISTINCT order_id)) OVER (),
    2
) AS DECIMAL(5,2)) AS usage_percentage,

    ROUND
    (
        SUM(payment_value),
        2
    ) AS total_revenue,

    ROUND
    (
        AVG(payment_value * 1.0),
        2
    ) AS average_payment_value,

    DENSE_RANK() OVER
    (
        ORDER BY COUNT(DISTINCT order_id) DESC
    ) AS usage_rank

FROM order_payments
WHERE payment_type <> 'not_defined'

GROUP BY payment_type

ORDER BY usage_rank;




/*==============================================================
INSTALLMENT RANGE ANALYSIS

Objective:
Analyze customer spending across installment ranges by
comparing order volume, revenue and average payment
value.

==============================================================*/

WITH installment_ranges AS
(
    SELECT

        CASE

            WHEN payment_installments = 1
                THEN 'Single Payment'

            WHEN payment_installments BETWEEN 2 AND 3
                THEN 'Short-Term (2-3)'

            WHEN payment_installments BETWEEN 4 AND 6
                THEN 'Medium-Term (4-6)'

            WHEN payment_installments BETWEEN 7 AND 12
                THEN 'Long-Term (7-12)'

            ELSE 'Extended (13+)'

        END AS installment_range,

        order_id,
        payment_value

    FROM order_payments

    WHERE payment_installments > 0
)

SELECT

    installment_range,

    COUNT(DISTINCT order_id) AS total_orders,

    CAST(ROUND
    (
        COUNT(DISTINCT order_id) * 100.0 /
        SUM(COUNT(DISTINCT order_id)) OVER (),
        2
    ) AS DECIMAL(5,2)) AS usage_percentage,

    ROUND
    (
        AVG(payment_value * 1.0),
        2
    ) AS average_payment_value,

    ROUND
    (
        SUM(payment_value),
        2
    ) AS total_revenue

FROM installment_ranges

GROUP BY installment_range

ORDER BY

CASE installment_range

    WHEN 'Single Payment' THEN 1
    WHEN 'Short-Term (2-3)' THEN 2
    WHEN 'Medium-Term (4-6)' THEN 3
    WHEN 'Long-Term (7-12)' THEN 4
    ELSE 5

END;




/*==============================================================
PAYMENT METHOD BY ORDER VALUE SEGMENT

Objective:
Compare payment preferences across order value segments to
identify the most commonly used payment methods for
different purchase values.

==============================================================*/

WITH payment_segments AS
(
    SELECT

        CASE
            WHEN op.payment_value < 100 THEN 'Under 100'
            WHEN op.payment_value BETWEEN 100 AND 299.99 THEN '100 - 299'
            WHEN op.payment_value BETWEEN 300 AND 499.99 THEN '300 - 499'
            ELSE '500 & Above'
        END AS order_value_segment,

        op.payment_type,

        COUNT(DISTINCT op.order_id) AS total_orders


    FROM order_payments op

    WHERE op.payment_type <> 'not_defined'

    GROUP BY

        CASE
            WHEN op.payment_value < 100 THEN 'Under 100'
            WHEN op.payment_value BETWEEN 100 AND 299.99 THEN '100 - 299'
            WHEN op.payment_value BETWEEN 300 AND 499.99 THEN '300 - 499'
            ELSE '500 & Above'
        END,

        op.payment_type
)

SELECT

    order_value_segment,

    payment_type,

    total_orders,

	CAST( ROUND(
        total_orders * 100.0 /
        SUM(total_orders) OVER(PARTITION BY order_value_segment),
        2
    ) AS decimal(5,2)) AS usage_percentage,


    DENSE_RANK() OVER
    (
        PARTITION BY order_value_segment
        ORDER BY total_orders DESC
    ) AS payment_rank

FROM payment_segments

ORDER BY

CASE order_value_segment
    WHEN 'Under 100' THEN 1
    WHEN '100 - 299' THEN 2
    WHEN '300 - 499' THEN 3
    ELSE 4
END,

payment_rank;




/*==============================================================
PAYMENT METHOD PREFERENCE BY STATE

Objective:
Compare payment preferences across high-order-volume
states by analyzing payment method usage and identifying
the most preferred payment methods within each state.

==============================================================*/

WITH eligible_states AS
(
    SELECT
        c.customer_state
    FROM customers c
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_state
    HAVING COUNT(DISTINCT o.order_id) >= 1000
),

state_payment AS
(
    SELECT

        c.customer_state,

        op.payment_type,

        COUNT(DISTINCT o.order_id) AS total_orders

    FROM customers c

    INNER JOIN orders o
        ON c.customer_id = o.customer_id

    INNER JOIN order_payments op
        ON o.order_id = op.order_id

    INNER JOIN eligible_states es
        ON c.customer_state = es.customer_state

    WHERE op.payment_type <> 'not_defined'

    GROUP BY

        c.customer_state,
        op.payment_type
)

SELECT

    customer_state,

    payment_type,

    total_orders,

    ROUND
    (
        total_orders * 100.0 /
        SUM(total_orders) OVER(PARTITION BY customer_state),
        2
    ) AS usage_percentage,

    DENSE_RANK() OVER
    (
        PARTITION BY customer_state
        ORDER BY total_orders DESC
    ) AS payment_rank

FROM state_payment

ORDER BY
    customer_state desc,
    usage_percentage desc;

SELECT
    ROUND(AVG(payment_installments * 1.0), 2) AS avg_installments
FROM order_payments;