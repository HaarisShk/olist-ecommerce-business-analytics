/*==============================================================
                 SELLER ANALYTICS

Description : Analyze seller performance, marketplace
              competition and regional contribution to
              identify high-performing sellers and business
              opportunities.

==============================================================*/


/*==============================================================
SELLER PERFORMANCE RANKING

Objective:
Rank sellers based on revenue, order volume and average
order value to identify the marketplace's top-performing
sellers.

==============================================================*/

SELECT

    seller_id,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND
    (
        SUM(price),
        2
    ) AS total_revenue,

    ROUND
    (
        SUM(price) * 1.0 /
        COUNT(DISTINCT order_id),
        2
    ) AS average_order_value,

    DENSE_RANK() OVER
    (
        ORDER BY SUM(price) DESC
    ) AS revenue_rank,
	
	DENSE_RANK() OVER
(
    ORDER BY COUNT(DISTINCT order_id) DESC
) AS order_rank

FROM vw_item_details

GROUP BY seller_id

ORDER BY total_revenue DESC, total_orders DESC;



/*==============================================================
SELLER CATEGORY COMPETITION

Objective:
Evaluate seller competition across product categories by
analyzing seller participation, revenue generation and
average revenue per seller.

==============================================================*/

SELECT

    product_category,

    COUNT(DISTINCT seller_id) AS total_sellers,

    ROUND
    (
        SUM(price),
        2
    ) AS total_revenue,

    ROUND
    (
        SUM(price) * 1.0 /
        COUNT(DISTINCT seller_id),
        2
    ) AS revenue_per_seller,

    DENSE_RANK() OVER
    (
        ORDER BY COUNT(DISTINCT seller_id) DESC
    ) AS competition_rank

FROM vw_item_details

GROUP BY product_category

ORDER BY competition_rank;



/*==============================================================
SELLER STATE PERFORMANCE

Objective:
Compare seller performance across states by analyzing seller
count, order volume, revenue and revenue generated per
seller.

==============================================================*/

SELECT

    seller_state,

    COUNT(DISTINCT seller_id) AS total_sellers,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND
    (
        SUM(price),
        2
    ) AS total_revenue,

    ROUND
    (
        SUM(price) * 1.0 /
        COUNT(DISTINCT seller_id),
        2
    ) AS revenue_per_seller,

    DENSE_RANK() OVER
    (
        ORDER BY SUM(price) DESC
    ) AS revenue_rank

FROM vw_item_details

GROUP BY seller_state
HAVING COUNT(DISTINCT seller_id) >= 10

ORDER BY revenue_rank;


