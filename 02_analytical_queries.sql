-- ============================================================
-- Retail Sales Analytics — Business Query Library
-- Organized from basic -> advanced SQL concepts
-- ============================================================

-- 1. Basic filter + sort: Top 10 highest-value completed orders
SELECT o.order_id, c.first_name, c.last_name, o.order_date,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS order_total
FROM orders o
JOIN customers c   ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY o.order_id, c.first_name, c.last_name, o.order_date
ORDER BY order_total DESC
LIMIT 10;

-- 2. INNER JOIN across 3 tables: revenue by category
SELECT cat.category_name,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue,
       SUM(oi.quantity) AS units_sold
FROM order_items oi
JOIN products p    ON p.product_id = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id
JOIN orders o       ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY cat.category_name
ORDER BY total_revenue DESC;

-- 3. LEFT JOIN: customers who have never placed an order
SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- 4. SELF JOIN: employees and their managers
SELECT e.first_name || ' ' || e.last_name AS employee,
       m.first_name || ' ' || m.last_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
ORDER BY manager;

-- 5. GROUP BY + HAVING: stores with more than 500 completed orders
SELECT s.store_name, COUNT(*) AS completed_orders
FROM orders o
JOIN stores s ON s.store_id = o.store_id
WHERE o.order_status = 'Completed'
GROUP BY s.store_name
HAVING COUNT(*) > 500
ORDER BY completed_orders DESC;

-- 6. Subquery: products priced above the overall average price
SELECT product_name, unit_price
FROM products
WHERE unit_price > (SELECT AVG(unit_price) FROM products)
ORDER BY unit_price DESC;

-- 7. Correlated subquery: each product's rank of price within its category
SELECT p.product_name, p.unit_price, p.category_id,
       (SELECT COUNT(*) FROM products p2
        WHERE p2.category_id = p.category_id AND p2.unit_price > p.unit_price) + 1 AS price_rank_in_category
FROM products p
ORDER BY p.category_id, price_rank_in_category;

-- 8. CTE + Window function: monthly revenue with month-over-month growth %
WITH monthly_revenue AS (
    SELECT strftime('%Y-%m', o.order_date) AS month,
           SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY month
)
SELECT month, ROUND(revenue, 2) AS revenue,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2) AS change_vs_prev_month,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month), 1) AS pct_growth
FROM monthly_revenue
ORDER BY month;

-- 9. Window function: rank products by revenue within each category
SELECT category_name, product_name, revenue,
       RANK() OVER (PARTITION BY category_name ORDER BY revenue DESC) AS rank_in_category
FROM (
    SELECT cat.category_name, p.product_name,
           SUM(oi.quantity * oi.unit_price) AS revenue
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    JOIN categories cat ON cat.category_id = p.category_id
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY cat.category_name, p.product_name
) t;

-- 10. Running total: cumulative revenue over time
WITH daily AS (
    SELECT o.order_date, SUM(oi.quantity * oi.unit_price) AS daily_revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_date
)
SELECT order_date, daily_revenue,
       ROUND(SUM(daily_revenue) OVER (ORDER BY order_date), 2) AS running_total
FROM daily
ORDER BY order_date;

-- 11. Customer Lifetime Value (CLV): total spend + order count per customer
SELECT c.customer_id, c.first_name, c.last_name, c.customer_segment,
       COUNT(DISTINCT o.order_id) AS num_orders,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS lifetime_value
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id AND o.order_status = 'Completed'
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_segment
ORDER BY lifetime_value DESC
LIMIT 20;

-- 12. Churn risk: customers with no completed order in the last 90 days (relative to latest order date in data)
WITH last_date AS (SELECT MAX(order_date) AS max_date FROM orders),
     last_order AS (
       SELECT customer_id, MAX(order_date) AS last_order_date
       FROM orders
       WHERE order_status = 'Completed'
       GROUP BY customer_id
     )
SELECT c.customer_id, c.first_name, c.last_name, lo.last_order_date
FROM customers c
JOIN last_order lo ON lo.customer_id = c.customer_id
CROSS JOIN last_date
WHERE julianday(last_date.max_date) - julianday(lo.last_order_date) > 90
ORDER BY lo.last_order_date;

-- 13. RFM-style segmentation (Recency, Frequency, Monetary) — simplified
WITH last_date AS (SELECT MAX(order_date) AS max_date FROM orders),
     rfm AS (
        SELECT o.customer_id,
               julianday((SELECT max_date FROM last_date)) - julianday(MAX(o.order_date)) AS recency_days,
               COUNT(DISTINCT o.order_id) AS frequency,
               SUM(oi.quantity * oi.unit_price) AS monetary
        FROM orders o
        JOIN order_items oi ON oi.order_id = o.order_id
        WHERE o.order_status = 'Completed'
        GROUP BY o.customer_id
     )
SELECT customer_id, ROUND(recency_days,0) AS recency_days, frequency, ROUND(monetary,2) AS monetary,
       CASE
         WHEN frequency >= 6 AND monetary > 10000 THEN 'VIP'
         WHEN frequency >= 3 THEN 'Regular'
         ELSE 'Occasional'
       END AS rfm_segment
FROM rfm
ORDER BY monetary DESC
LIMIT 20;

-- 14. Profit margin analysis per product
SELECT p.product_name,
       ROUND(SUM(oi.quantity * (oi.unit_price - p.unit_cost)), 2) AS total_profit,
       ROUND(AVG((p.unit_price - p.unit_cost) / p.unit_price) * 100, 1) AS avg_margin_pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_name
ORDER BY total_profit DESC;

-- 15. Return/cancellation rate by store
SELECT s.store_name,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS returned,
       SUM(CASE WHEN o.order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
       ROUND(100.0 * SUM(CASE WHEN o.order_status IN ('Returned','Cancelled') THEN 1 ELSE 0 END) / COUNT(*), 1) AS problem_rate_pct
FROM orders o
JOIN stores s ON s.store_id = o.store_id
GROUP BY s.store_name
ORDER BY problem_rate_pct DESC;
