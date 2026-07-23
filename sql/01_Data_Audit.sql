/*==============================================================
                    DATA AUDIT & QUALITY CHECKS

Project     : Olist E-Commerce Business Analytics

Description : Validate dataset quality before performing
              business analysis by checking table sizes,
              key uniqueness, referential integrity,
              duplicate records, missing values and
              business rule validations.

==============================================================*/


/*==============================================================
TABLE ROW COUNTS
==============================================================*/

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation;

/*==============================================================
PRIMARY KEY VALIDATION
==============================================================*/
--Customers
SELECT
COUNT(*) AS total_rows,
COUNT(DISTINCT customer_id) AS distinct_customer_ids
FROM customers;

--Orders
SELECT
COUNT(*) AS total_rows,
COUNT(DISTINCT order_id) AS distinct_order_ids
FROM orders;

--Products
SELECT
COUNT(*) AS total_rows,
COUNT(DISTINCT product_id) AS distinct_product_ids
FROM products;

--Sellers
SELECT
COUNT(*) AS total_rows,
COUNT(DISTINCT seller_id) AS distinct_seller_ids
FROM sellers;

/*==============================================================
FOREIGN KEY INTEGRITY CHECKS
==============================================================*/

--Orders --> Customers
SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

--Order Items --> Orders
SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o
ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

--Order Items --> Products
SELECT COUNT(*) AS orphan_products
FROM order_items oi
LEFT JOIN products p
ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

--Order Items --> Sellers
SELECT COUNT(*) AS orphan_sellers
FROM order_items oi
LEFT JOIN sellers s
ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

--Payments → Orders
SELECT COUNT(*) AS orphan_payments
FROM order_payments op
LEFT JOIN orders o
ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

--Reviews → Orders
SELECT COUNT(*) AS orphan_reviews
FROM order_reviews r
LEFT JOIN orders o
ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

/*==============================================================
DUPLICATE RECORD CHECKS
==============================================================*/

--Customers
SELECT customer_id,
COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

--Orders
SELECT order_id,
COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

--Products
SELECT product_id,
COUNT(*) AS duplicate_count
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

--Sellers
SELECT seller_id,
COUNT(*) AS duplicate_count
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

/*==============================================================
NULL VALUE ANALYSIS
==============================================================*/

--Customers
SELECT
SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS null_customer_city,
SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS null_customer_state
FROM customers;

--Orders
SELECT
SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS null_purchase_date,
SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS null_order_status,
SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS null_estimated_delivery
FROM orders;

--Products
SELECT
SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category
FROM products;

/*==============================================================
DATE VALIDATION
==============================================================*/

--Delivered before purchase
SELECT COUNT(*) AS invalid_delivery_dates
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

--Estimated delivery before purchase
SELECT COUNT(*) AS invalid_estimated_dates
FROM orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;

/*==============================================================
BUSINESS RULE VALIDATION
==============================================================*/

--Invalid Review Scores
SELECT COUNT(*) AS invalid_review_scores
FROM order_reviews
WHERE review_score NOT BETWEEN 1 AND 5;

--Negative Product Price
SELECT COUNT(*) AS invalid_prices
FROM order_items
WHERE price < 0;

--Negative Freight Charges
SELECT COUNT(*) AS invalid_freight_values
FROM order_items
WHERE freight_value < 0;

--Invalid Payment Values
SELECT COUNT(*) AS invalid_payment_values
FROM order_payments
WHERE payment_value < 0;