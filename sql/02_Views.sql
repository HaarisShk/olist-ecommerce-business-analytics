/*==============================================================
VIEW: vw_order_summary

Purpose:
Create an order-level analytical dataset by combining
orders, customers and payment information.

Used In:
• Executive Analytics
• Customer Analytics
• Delivery Analytics

==============================================================*/

CREATE VIEW vw_order_summary
AS

SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    o.order_status,

    c.customer_city,
    c.customer_state,

    ps.order_value AS order_value,

    COUNT(oi.order_item_id) AS total_items

FROM orders o

INNER JOIN customers c
    ON o.customer_id = c.customer_id

LEFT JOIN
(
    SELECT
        order_id,
        SUM(payment_value) AS order_value
    FROM order_payments
    GROUP BY order_id
) ps
    ON o.order_id = ps.order_id

LEFT JOIN order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.order_status,
    c.customer_city,
    c.customer_state,
    ps.order_value;

GO


/*==============================================================
VIEW: vw_item_details

Purpose:
Create an item-level analytical dataset by combining
products, sellers and order information.

Used In:
• Product Analytics
• Seller Analytics
• Payment Analytics

==============================================================*/

CREATE VIEW vw_item_details
AS

SELECT
    oi.order_id,
    oi.order_item_id,

    oi.product_id,
    oi.seller_id,

    o.order_purchase_timestamp,
    o.order_status,

    COALESCE
    (
        ct.product_category_name_english,
        p.product_category_name
    ) AS product_category,

    oi.price,
    oi.freight_value,

    oi.shipping_limit_date,

    s.seller_city,
    s.seller_state

FROM order_items oi

INNER JOIN orders o
    ON oi.order_id = o.order_id

INNER JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name

INNER JOIN sellers s
    ON oi.seller_id = s.seller_id;

GO

/*==============================================================
VIEW: vw_customer_type_summary

Purpose:
Summarize one-time and repeat customer behaviour for
customer analytics and dashboard reporting.

Used In:
• Customer Analytics Dashboard

==============================================================*/

CREATE VIEW vw_customer_type_summary
AS

WITH customer_summary AS
(
    SELECT
        customer_unique_id,
        COUNT(*) AS total_orders,
        SUM(order_value) AS total_revenue
    FROM vw_order_summary
    GROUP BY customer_unique_id
)

SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS customer_count,

    ROUND
    (
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,

    SUM(total_orders) AS total_orders,

    SUM(total_revenue) AS total_revenue,

    ROUND
    (
        SUM(total_revenue) * 1.0 /
        SUM(total_orders),
        2
    ) AS average_order_value,

    ROUND
    (
        SUM(total_revenue) * 1.0 /
        COUNT(*),
        2
    ) AS average_customer_value

FROM customer_summary

GROUP BY
    CASE
        WHEN total_orders = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END;

GO

/*==============================================================
VIEW: vw_customer_rfm_summary

Purpose:
Create customer RFM segments to support customer
segmentation and retention analysis.

Used In:
• Customer Analytics Dashboard

==============================================================*/

CREATE VIEW vw_customer_rfm_summary
AS

WITH customer_rfm AS
(
    SELECT
        customer_unique_id,

        DATEDIFF
        (
            DAY,
            MAX(order_purchase_timestamp),
            (SELECT MAX(order_purchase_timestamp)
             FROM vw_order_summary)
        ) AS recency,

        COUNT(*) AS frequency,

        SUM(order_value) AS monetary

    FROM vw_order_summary

    GROUP BY customer_unique_id
),

rfm_scores AS
(
    SELECT
        customer_unique_id,

        NTILE(5) OVER (ORDER BY recency ASC) AS recency_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency BETWEEN 4 AND 5 THEN 4
            ELSE 5
        END AS frequency_score,

        NTILE(5) OVER (ORDER BY monetary DESC) AS monetary_score

    FROM customer_rfm
),

customer_segments AS
(
    SELECT
        CASE
            WHEN recency_score >= 4
             AND frequency_score >= 3
                THEN 'Champions'

            WHEN recency_score >= 3
             AND monetary_score >= 4
                THEN 'Loyal Customers'

            WHEN recency_score >= 4
             AND frequency_score <= 2
                THEN 'Potential Loyalists'

            WHEN recency_score <= 2
             AND (frequency_score >= 3
                  OR monetary_score >= 4)
                THEN 'At Risk'

            ELSE 'Need Attention'
        END AS customer_segment

    FROM rfm_scores
)

SELECT

    customer_segment,

    COUNT(*) AS total_customers,

    ROUND
    (
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM customer_segments

GROUP BY customer_segment;

GO

/*==============================================================
VIEW: vw_delivery_dashboard

Purpose:
Generate delivery KPIs including delivery time,
on-time deliveries and delayed deliveries for
dashboard reporting.

Used In:
• Delivery Analytics Dashboard

==============================================================*/

CREATE VIEW vw_delivery_dashboard
AS

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
        ) * 100.0 /
        COUNT(*),
        2
    ) AS on_time_delivery_percentage

FROM vw_order_summary

WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL;

GO

/*==============================================================
VIEW: vw_delivery_state_performance

Purpose:
Summarize delivery performance across customer
states to evaluate regional logistics efficiency.

Used In:
• Delivery Analytics Dashboard

==============================================================*/

CREATE VIEW vw_delivery_state_performance
AS

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
    ) AS on_time_delivery_percentage

FROM vw_order_summary

WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL

GROUP BY customer_state

HAVING COUNT(*) >= 100;

GO

