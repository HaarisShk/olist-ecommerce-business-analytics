/*==============================================================
                 DELIVERY ANALYTICS

Description : Analyze delivery efficiency, regional logistics
              performance and product category delivery trends
              to evaluate operational performance and service
              reliability.

==============================================================*/


/*==============================================================
DELIVERY PERFORMANCE DASHBOARD

Objective:
Measure overall delivery performance by analyzing delivery
time, on-time deliveries and delayed orders to evaluate
logistics efficiency.

==============================================================*/

SELECT

    COUNT(*) AS delivered_orders,

    ROUND
    (
        AVG
        (
            DATEDIFF
            (
                DAY,
                order_purchase_timestamp,
                order_delivered_customer_date
            ) * 1.0
        ),
        2
    ) AS average_delivery_days,

    SUM
    (
        CASE
            WHEN order_delivered_customer_date
                 <= order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS on_time_orders,

    SUM
    (
        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS delayed_orders,

    ROUND
    (
        SUM
        (
            CASE
                WHEN order_delivered_customer_date
                     <= order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) * 100.0
        / COUNT(*),
        2
    ) AS on_time_delivery_percentage

FROM vw_order_summary

WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL;



/*==============================================================
STATE-WISE DELIVERY PERFORMANCE

Objective:
Compare delivery performance across customer states by
analyzing delivery time and on-time delivery rates to
identify regional logistics differences.

==============================================================*/

SELECT

    customer_state,

    COUNT(*) AS delivered_orders,

    ROUND
    (
        AVG
        (
            DATEDIFF
            (
                DAY,
                order_purchase_timestamp,
                order_delivered_customer_date
            ) * 1.0
        ),
        2
    ) AS average_delivery_days,

    ROUND
    (
        SUM
        (
            CASE
                WHEN order_delivered_customer_date
                     <= order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) * 100.0 /
        COUNT(*),
        2
    ) AS on_time_delivery_percentage,

    DENSE_RANK() OVER
    (
        ORDER BY
        AVG
        (
            DATEDIFF
            (
                DAY,
                order_purchase_timestamp,
                order_delivered_customer_date
            ) 
        )DESC
    ) AS slowest_delivery_rank

FROM vw_order_summary

WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL

GROUP BY customer_state

HAVING COUNT(*) >= 100

ORDER BY slowest_delivery_rank;


/*==============================================================
PRODUCT CATEGORY DELIVERY PERFORMANCE

Objective:
Evaluate delivery performance across product categories by
comparing delivery time and on-time delivery rates to
identify categories requiring logistics improvements.

==============================================================*/

SELECT

    product_category,

    COUNT(DISTINCT v.order_id) AS delivered_orders,

    ROUND
    (
        AVG
        (
            DATEDIFF
            (
                DAY,
                o.order_purchase_timestamp,
                o.order_delivered_customer_date
            ) * 1.0
        ),
        2
    ) AS average_delivery_days,

    ROUND
    (
        COUNT
        (
            DISTINCT CASE
                WHEN o.order_delivered_customer_date
                     <= o.order_estimated_delivery_date
                THEN v.order_id
            END
        ) * 100.0
        /
        COUNT(DISTINCT v.order_id),
        2
    ) AS on_time_delivery_percentage,

    DENSE_RANK() OVER
    (
        ORDER BY
        AVG
        (
            DATEDIFF
            (
                DAY,
                o.order_purchase_timestamp,
                o.order_delivered_customer_date
            )
        ) DESC
    ) AS slowest_delivery_rank

FROM vw_item_details v

INNER JOIN vw_order_summary o
    ON v.order_id = o.order_id

WHERE o.order_status = 'delivered'

GROUP BY product_category

HAVING COUNT(DISTINCT v.order_id) >= 100

ORDER BY slowest_delivery_rank;