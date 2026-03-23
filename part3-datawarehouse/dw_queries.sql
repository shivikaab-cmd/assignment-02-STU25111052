-- ============================================================
-- PART 3: Data Warehouse Analytical Queries
-- File: part3-datawarehouse/dw_queries.sql
-- Run AFTER star_schema.sql
-- ============================================================

-- Q1: Total sales revenue by product category for each month
-- Joins fact_sales → dim_date → dim_product to group net_revenue
-- by year-month and category; result drives category trend reports.
SELECT
    dd.year,
    dd.month_name,
    dd.month_num,
    dp.category,
    SUM(fs.quantity_sold)                        AS total_units_sold,
    SUM(fs.quantity_sold * fs.unit_price)        AS gross_revenue,
    SUM(fs.discount_amount)                      AS total_discounts,
    SUM(fs.quantity_sold * fs.unit_price
        - fs.discount_amount)                    AS net_revenue
FROM fact_sales   fs
JOIN dim_date     dd ON fs.date_key    = dd.date_key
JOIN dim_product  dp ON fs.product_key = dp.product_key
GROUP BY dd.year, dd.month_num, dd.month_name, dp.category
ORDER BY dd.year, dd.month_num, dp.category;

-- Q2: Top 2 performing stores by total revenue
-- Aggregates net_revenue per store across all time; used by regional
-- management to identify flagship vs underperforming locations.
SELECT
    ds.store_id,
    ds.store_name,
    ds.city,
    ds.store_type,
    COUNT(DISTINCT fs.sale_id)                          AS total_transactions,
    SUM(fs.quantity_sold)                               AS total_units_sold,
    SUM(fs.quantity_sold * fs.unit_price - fs.discount_amount) AS total_net_revenue
FROM fact_sales fs
JOIN dim_store  ds ON fs.store_key = ds.store_key
GROUP BY ds.store_key, ds.store_id, ds.store_name, ds.city, ds.store_type
ORDER BY total_net_revenue DESC
LIMIT 2;

-- Q3: Month-over-month sales trend across all stores
-- Uses a self-join on dim_date (via a subquery) to compute the
-- previous month's revenue and calculate the MoM growth percentage.
-- LAG() is used here (supported in PostgreSQL/SQLite 3.25+).
WITH monthly_revenue AS (
    SELECT
        dd.year,
        dd.month_num,
        dd.month_name,
        SUM(fs.quantity_sold * fs.unit_price - fs.discount_amount) AS net_revenue
    FROM fact_sales fs
    JOIN dim_date   dd ON fs.date_key = dd.date_key
    GROUP BY dd.year, dd.month_num, dd.month_name
)
SELECT
    year,
    month_name,
    month_num,
    net_revenue,
    LAG(net_revenue) OVER (ORDER BY year, month_num)  AS prev_month_revenue,
    ROUND(
        100.0 * (net_revenue - LAG(net_revenue) OVER (ORDER BY year, month_num))
              / NULLIF(LAG(net_revenue) OVER (ORDER BY year, month_num), 0),
        2
    )                                                  AS mom_growth_pct
FROM monthly_revenue
ORDER BY year, month_num;
