/*==============================================================
                      EXECUTIVE ANALYTICS

Description:
This script analyzes overall marketplace performance using
key business metrics such as revenue, orders, customers,
sellers and sales trends.
================================================================*/



/*==============================================================
EXECUTIVE KPI SUMMARY

Objective:
Provide a high-level overview of marketplace performance by
calculating key business metrics, including revenue, orders,
customers, sellers, average order value and average items per
order.
==============================================================*/

SELECT
    SUM(order_value) AS total_gmv,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,

    (
        SELECT COUNT(DISTINCT seller_id)
        FROM vw_item_details
    ) AS unique_sellers,

    AVG(order_value) AS average_order_value,
    AVG(CAST(total_items AS DECIMAL(10,2))) AS average_items_per_order

FROM vw_order_summary;

/*==============================================================
MONTHLY BUSINESS PERFORMANCE

Objective:
Evaluate monthly marketplace performance by tracking order
volume, revenue, average order value and month-over-month
revenue growth to identify overall business trends.
==============================================================*/

WITH monthly_summary AS
(
    SELECT
        DATEFROMPARTS
        (
            YEAR(order_purchase_timestamp),
            MONTH(order_purchase_timestamp),
            1
        ) AS order_month,

        COUNT(*) AS total_orders,

        SUM(order_value) AS total_gmv,

        AVG(order_value) AS average_order_value

    FROM vw_order_summary

    WHERE order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp < '2018-09-01'

    GROUP BY
        DATEFROMPARTS
        (
            YEAR(order_purchase_timestamp),
            MONTH(order_purchase_timestamp),
            1
        )
),

monthly_growth AS
(
    SELECT
        order_month,
        total_orders,
        total_gmv,
        ROUND(average_order_value, 2) AS average_order_value,

        LAG(total_gmv)
        OVER(ORDER BY order_month) AS previous_month_gmv

    FROM monthly_summary
)

SELECT
    FORMAT(order_month, 'yyyy-MM') AS order_month,
    total_orders,
    total_gmv,
    average_order_value,
    previous_month_gmv,

    ROUND
    (
        (
            (total_gmv - previous_month_gmv)
            * 100.0
        ) / previous_month_gmv,
        2
    ) AS mom_growth_pct

FROM monthly_growth

ORDER BY order_month;


/*==============================================================
PRODUCT CATEGORY PERFORMANCE

Objective:
Measure the performance of product categories by comparing
revenue, sales volume, average selling price and contribution
to overall marketplace revenue.
==============================================================*/

WITH category_summary AS
(
    SELECT
        ISNULL(product_category, 'Unknown') AS product_category,

        SUM(price) AS category_revenue,

        COUNT(*) AS items_sold,

        AVG(price) AS average_selling_price

    FROM vw_item_details

    GROUP BY
        ISNULL(product_category, 'Unknown')
)

SELECT
    product_category,

    category_revenue,

    items_sold,

    ROUND(average_selling_price, 2) AS average_selling_price,

    RANK() OVER
    (
        ORDER BY category_revenue DESC
    ) AS revenue_rank,

    ROUND
    (
        category_revenue * 100.0 /
        SUM(category_revenue) OVER (),
        2
    ) AS revenue_contribution_pct

FROM category_summary

ORDER BY category_revenue DESC;


/*==============================================================
CUSTOMER STATE PERFORMANCE

Objective:
Assess marketplace performance across customer states by
analyzing revenue, order volume, customer count and each
state's contribution to total revenue.
==============================================================*/

WITH state_summary AS
(
    SELECT
        customer_state,

        SUM(order_value) AS total_gmv,

        COUNT(*) AS total_orders,

        COUNT(DISTINCT customer_unique_id) AS unique_customers

    FROM vw_order_summary

    GROUP BY customer_state
)

SELECT
    customer_state,

    total_gmv,

    total_orders,

    unique_customers,

    ROUND
    (
        total_gmv * 100.0 /
        SUM(total_gmv) OVER (),
        2
    ) AS revenue_share_pct

FROM state_summary

ORDER BY total_gmv DESC;


/*==============================================================
PARETO ANALYSIS (80/20 RULE)

Objective:
Determine whether a small number of product categories
generate the majority of marketplace revenue using the
Pareto principle.
==============================================================*/

WITH category_summary AS
(
    SELECT
        ISNULL(product_category, 'Unknown') AS product_category,
        SUM(price) AS category_revenue

    FROM vw_item_details

    GROUP BY ISNULL(product_category, 'Unknown')
),

pareto_analysis AS
(
    SELECT
        product_category,
        category_revenue,

        SUM(category_revenue) OVER
        (
            ORDER BY category_revenue DESC
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_revenue,

        SUM(category_revenue) OVER () AS total_revenue

    FROM category_summary
)

SELECT
    product_category,

    category_revenue,

    cumulative_revenue,

    ROUND
    (
        cumulative_revenue * 100.0 /
        total_revenue,
        2
    ) AS cumulative_revenue_pct

FROM pareto_analysis

ORDER BY category_revenue DESC;
