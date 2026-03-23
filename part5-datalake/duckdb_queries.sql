-- ============================================================
-- PART 5: Data Lake — DuckDB Cross-Format Queries
-- File: part5-datalake/duckdb_queries.sql
-- Files read DIRECTLY — no CREATE TABLE statements allowed.
-- Run with: duckdb < duckdb_queries.sql
-- Or paste into DuckDB CLI / Python duckdb.sql()
-- ============================================================
-- File paths assume DuckDB is run from the repository root.
-- Adjust paths if running from a different working directory.
-- ============================================================

-- Q1: List all customers along with the total number of orders they have placed
-- Reads customers.csv and orders.json directly via DuckDB auto-detection.
-- LEFT JOIN ensures customers with zero orders appear with count = 0.
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    c.state,
    COUNT(o.order_id)  AS total_orders
FROM read_csv_auto('datasets/customers.csv')  AS c
LEFT JOIN read_json_auto('datasets/orders.json') AS o
       ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.city, c.state
ORDER BY total_orders DESC, c.customer_name ASC;

-- Q2: Find the top 3 customers by total order value
-- Reads orders.json for quantity + unit_price; joins customers.csv
-- to resolve customer names. total_order_value = SUM(quantity * unit_price).
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    ROUND(SUM(o.quantity * o.unit_price), 2) AS total_order_value
FROM read_csv_auto('datasets/customers.csv')     AS c
JOIN read_json_auto('datasets/orders.json')      AS o
  ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY total_order_value DESC
LIMIT 3;

-- Q3: List all products purchased by customers from Bangalore
-- Three-way join across all three file formats:
--   customers.csv  (filter city = 'Bangalore')
--   orders.json    (link customer → product)
--   products.parquet (resolve product details)
-- DISTINCT prevents duplicates when a product was bought multiple times.
SELECT DISTINCT
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    p.unit_price
FROM read_csv_auto('datasets/customers.csv')    AS c
JOIN read_json_auto('datasets/orders.json')     AS o  ON c.customer_id = o.customer_id
JOIN read_parquet('datasets/products.parquet')  AS p  ON o.product_id  = p.product_id
WHERE LOWER(TRIM(c.city)) = 'bangalore'
ORDER BY p.category, p.product_name;

-- Q4: Join all three files to show: customer name, order date, product name, and quantity
-- Full three-way join across CSV + JSON + Parquet; displays the complete
-- order line-item view — the canonical "order confirmation" report.
SELECT
    c.customer_name,
    c.city                   AS customer_city,
    o.order_date,
    p.product_name,
    p.category,
    o.quantity,
    ROUND(o.quantity * p.unit_price, 2) AS line_total
FROM read_csv_auto('datasets/customers.csv')   AS c
JOIN read_json_auto('datasets/orders.json')    AS o  ON c.customer_id = o.customer_id
JOIN read_parquet('datasets/products.parquet') AS p  ON o.product_id  = p.product_id
ORDER BY o.order_date DESC, c.customer_name ASC;
