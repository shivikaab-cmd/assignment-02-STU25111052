-- ============================================================
-- PART 1: SQL Queries
-- File: part1-rdbms/queries.sql
-- Compatible with: SQLite / PostgreSQL (minor dialect notes below)
-- Run AFTER executing schema_design.sql
-- ============================================================

-- Q1: List all customers from Mumbai along with their total order value
-- Joins customers → orders → order_items; filters by city = 'Mumbai';
-- excludes cancelled orders; sums (quantity × unit_price) per customer.
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_order_value
FROM customers c
LEFT JOIN orders      o  ON c.customer_id = o.customer_id
                         AND o.status != 'Cancelled'
LEFT JOIN order_items oi ON o.order_id    = oi.order_id
WHERE c.city = 'Mumbai'
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY total_order_value DESC;

-- Q2: Find the top 3 products by total quantity sold
-- Aggregates quantity across all non-cancelled order_items per product;
-- ranks them by descending total quantity and limits to top 3.
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity)                 AS total_qty_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM products    p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders      o  ON oi.order_id  = o.order_id
WHERE o.status != 'Cancelled'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_qty_sold DESC
LIMIT 3;

-- Q3: List all sales representatives and the number of unique customers they have handled
-- Counts DISTINCT customer_id per rep to avoid double-counting customers
-- who placed multiple orders with the same rep.
SELECT
    sr.rep_id,
    sr.rep_name,
    sr.region,
    COUNT(DISTINCT o.customer_id) AS unique_customers_handled
FROM sales_reps sr
LEFT JOIN orders o ON sr.rep_id = o.rep_id
GROUP BY sr.rep_id, sr.rep_name, sr.region
ORDER BY unique_customers_handled DESC;

-- Q4: Find all orders where the total value exceeds 10,000, sorted by value descending
-- Computes per-order total in a subquery/CTE then filters with HAVING.
-- Only non-cancelled orders are considered.
SELECT
    o.order_id,
    c.customer_name,
    o.order_date,
    o.status,
    SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders      o
JOIN customers   c  ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id    = oi.order_id
WHERE o.status != 'Cancelled'
GROUP BY o.order_id, c.customer_name, o.order_date, o.status
HAVING SUM(oi.quantity * oi.unit_price) > 10000
ORDER BY order_total DESC;

-- Q5: Identify any products that have never been ordered
-- Uses a LEFT JOIN from products to order_items; rows where
-- oi.product_id IS NULL indicate a product with zero sales history.
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL
ORDER BY p.product_id;
