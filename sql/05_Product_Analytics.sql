/*
==========================================================
Query 1: Category Pricing Analysis

Business Question:
Which product categories have the highest and
lowest average selling prices?

Business Logic:
- Calculates the average selling price for each category.
- Also shows the minimum and maximum selling price.
- Categories are ranked by average selling price.
==========================================================
*/

SELECT

    product_category,

    ROUND
    (
        AVG(price),
        2
    ) AS average_selling_price,

    ROUND
    (
        MIN(price),
        2
    ) AS minimum_price,

    ROUND
    (
        MAX(price),
        2
    ) AS maximum_price,

    RANK() OVER
    (
        ORDER BY AVG(price) DESC
    ) AS price_rank

FROM vw_item_details

GROUP BY product_category

ORDER BY average_selling_price DESC;



/*
==========================================================
Query 2: Volume vs Value Analysis

Business Question:
Which product categories are driven by
sales volume versus premium pricing?

Business Logic:
- Units Sold measures demand.
- Average Selling Price measures product value.
- Revenue Rank shows overall business contribution.
==========================================================
*/

SELECT

    product_category,

    COUNT(*) AS units_sold,

    ROUND
    (
        AVG(price),
        2
    ) AS average_selling_price,

    ROUND
    (
        SUM(price),
        2
    ) AS total_revenue,

    DENSE_RANK() OVER
    (
        ORDER BY COUNT(*) DESC
    ) AS volume_rank,

    DENSE_RANK() OVER
    (
        ORDER BY AVG(price) DESC
    ) AS price_rank,

    DENSE_RANK() OVER
    (
        ORDER BY SUM(price) DESC
    ) AS revenue_rank

FROM vw_item_details

GROUP BY product_category

ORDER BY revenue_rank;


