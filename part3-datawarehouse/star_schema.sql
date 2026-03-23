-- ============================================================
-- PART 3: Data Warehouse — Star Schema
-- File: part3-datawarehouse/star_schema.sql
-- Source dataset: retail_transactions.csv
-- Compatible with: PostgreSQL 12+ / SQLite 3.31+
-- ============================================================

-- Drop in reverse dependency order for clean re-runs
DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_store;
DROP TABLE IF EXISTS dim_product;

-- ----------------------------------------------------------
-- Dimension: dim_date
-- Pre-computed calendar attributes avoid repeated date-parsing
-- in analytical queries and enable fast GROUP BY on month/quarter.
-- ----------------------------------------------------------
CREATE TABLE dim_date (
    date_key    INTEGER     PRIMARY KEY,   -- surrogate key: YYYYMMDD integer
    full_date   DATE        NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,
    day_num     INTEGER     NOT NULL,      -- 1=Monday … 7=Sunday
    week_num    INTEGER     NOT NULL,
    month_num   INTEGER     NOT NULL,
    month_name  VARCHAR(10) NOT NULL,
    quarter     INTEGER     NOT NULL,
    year        INTEGER     NOT NULL,
    is_weekend  INTEGER     NOT NULL       -- 0=Weekday, 1=Weekend (SQLite-safe)
);

INSERT INTO dim_date VALUES
(20240101, '2024-01-01', 'Monday',    1,  1,  1, 'January',   1, 2024, 0),
(20240115, '2024-01-15', 'Monday',    1,  3,  1, 'January',   1, 2024, 0),
(20240205, '2024-02-05', 'Monday',    1,  6,  2, 'February',  1, 2024, 0),
(20240220, '2024-02-20', 'Tuesday',   2,  8,  2, 'February',  1, 2024, 0),
(20240301, '2024-03-01', 'Friday',    5,  9,  3, 'March',     1, 2024, 0),
(20240312, '2024-03-12', 'Tuesday',   2, 11,  3, 'March',     1, 2024, 0),
(20240401, '2024-04-01', 'Monday',    1, 14,  4, 'April',     2, 2024, 0),
(20240415, '2024-04-15', 'Monday',    1, 16,  4, 'April',     2, 2024, 0),
(20240501, '2024-05-01', 'Wednesday', 3, 18,  5, 'May',       2, 2024, 0),
(20240610, '2024-06-10', 'Monday',    1, 24,  6, 'June',      2, 2024, 0);

-- ----------------------------------------------------------
-- Dimension: dim_store
-- One row per physical or online retail location.
-- Cleaned: consistent city casing (Title Case), no NULLs.
-- ----------------------------------------------------------
CREATE TABLE dim_store (
    store_key  INTEGER      PRIMARY KEY,
    store_id   VARCHAR(20)  NOT NULL UNIQUE,
    store_name VARCHAR(100) NOT NULL,
    city       VARCHAR(80)  NOT NULL,
    state      VARCHAR(80)  NOT NULL,
    store_type VARCHAR(30)  NOT NULL    -- 'Flagship' | 'Express' | 'Online'
);

INSERT INTO dim_store VALUES
(1, 'STR-001', 'RetailCo Mumbai Central',  'Mumbai',    'Maharashtra', 'Flagship'),
(2, 'STR-002', 'RetailCo Delhi Connaught', 'Delhi',     'Delhi',       'Flagship'),
(3, 'STR-003', 'RetailCo Bengaluru MG Rd', 'Bengaluru', 'Karnataka',   'Express'),
(4, 'STR-004', 'RetailCo Ahmedabad CG Rd', 'Ahmedabad', 'Gujarat',     'Express'),
(5, 'STR-005', 'RetailCo Online',          'Pan-India', 'Pan-India',   'Online');

-- ----------------------------------------------------------
-- Dimension: dim_product
-- One row per product SKU.
-- Cleaned: category is Title Case (raw data had mixed casing).
-- ----------------------------------------------------------
CREATE TABLE dim_product (
    product_key  INTEGER        PRIMARY KEY,
    product_id   VARCHAR(20)    NOT NULL UNIQUE,
    product_name VARCHAR(150)   NOT NULL,
    category     VARCHAR(80)    NOT NULL,
    sub_category VARCHAR(80)    NOT NULL,
    brand        VARCHAR(80)    NOT NULL,
    unit_price   DECIMAL(10,2)  NOT NULL CHECK (unit_price > 0)
);

INSERT INTO dim_product VALUES
(1, 'PRD-201', 'Sony WH-1000XM5 Headphones', 'Electronics', 'Audio',    'Sony',       29990.00),
(2, 'PRD-202', 'Levis 511 Slim Jeans',        'Clothing',    'Bottoms',  'Levis',       2999.00),
(3, 'PRD-203', 'India Gate Basmati Rice 5kg', 'Groceries',   'Staples',  'India Gate',   649.00),
(4, 'PRD-204', 'Nike Air Zoom Running Shoes', 'Footwear',    'Sports',   'Nike',        5499.00),
(5, 'PRD-205', 'Prestige Stainless Pan',      'Kitchenware', 'Cookware', 'Prestige',     799.00);

-- ----------------------------------------------------------
-- Fact Table: fact_sales
-- Grain: one row per order line item.
-- Measures: quantity_sold, unit_price, discount_amount, gross_revenue, net_revenue.
-- gross_revenue and net_revenue are stored (not computed) for compatibility.
-- ----------------------------------------------------------
CREATE TABLE fact_sales (
    sale_id         INTEGER        PRIMARY KEY,
    date_key        INTEGER        NOT NULL,
    store_key       INTEGER        NOT NULL,
    product_key     INTEGER        NOT NULL,
    quantity_sold   INTEGER        NOT NULL CHECK (quantity_sold > 0),
    unit_price      DECIMAL(10,2)  NOT NULL,
    discount_amount DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    gross_revenue   DECIMAL(12,2)  NOT NULL,  -- quantity_sold * unit_price
    net_revenue     DECIMAL(12,2)  NOT NULL,  -- gross_revenue - discount_amount
    FOREIGN KEY (date_key)    REFERENCES dim_date(date_key),
    FOREIGN KEY (store_key)   REFERENCES dim_store(store_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key)
);

-- ============================================================
-- DATA CLEANING APPLIED BEFORE INSERT (ETL transformation log)
-- ============================================================
-- The following issues existed in retail_transactions.csv RAW data
-- and were corrected before loading into the star schema:
--
-- Issue 1 — Date format inconsistency (fixed → ISO 8601 YYYY-MM-DD):
--   RAW:     "15/01/2024"  →  CLEAN: "2024-01-15"  (date_key: 20240115)
--   RAW:     "20-Feb-24"   →  CLEAN: "2024-02-20"  (date_key: 20240220)
--   RAW:     "2024-03-01"  →  CLEAN: "2024-03-01"  (already correct)
--
-- Issue 2 — Category casing inconsistency (fixed → Title Case):
--   RAW:     "electronics" / "ELECTRONICS" / "electroniCs"
--   CLEAN:   "Electronics"
--   RAW:     "clothing" / "CLOTHING"
--   CLEAN:   "Clothing"
--
-- Issue 3 — NULL unit_price rows (back-filled from dim_product):
--   RAW:     order_id=1008, product_id=PRD-203, unit_price=NULL
--   CLEAN:   unit_price=649.00  (sourced from dim_product.unit_price)
--
-- Issue 4 — NULL quantity rows (dropped — cannot impute):
--   RAW:     order_id=1011, quantity=NULL  → row EXCLUDED from load
--
-- All 15 rows below represent fully cleaned, validated data.
-- ============================================================

-- 15 fact rows — cleaned data: standardized dates, no NULLs, consistent casing
INSERT INTO fact_sales (sale_id, date_key, store_key, product_key, quantity_sold, unit_price, discount_amount, gross_revenue, net_revenue) VALUES
( 1, 20240101, 1, 1,  2, 29990.00, 1000.00,  59980.00,  58980.00),
( 2, 20240101, 1, 2,  5,  2999.00,    0.00,  14995.00,  14995.00),
( 3, 20240115, 2, 3, 10,   649.00,    0.00,   6490.00,   6490.00),
( 4, 20240115, 2, 4,  1,  5499.00,  500.00,   5499.00,   4999.00),
( 5, 20240205, 3, 5,  3,   799.00,    0.00,   2397.00,   2397.00),
( 6, 20240220, 4, 1,  1, 29990.00, 2999.00,  29990.00,  26991.00),
( 7, 20240301, 5, 2,  8,  2999.00,    0.00,  23992.00,  23992.00),
( 8, 20240301, 5, 3, 15,   649.00,  100.00,   9735.00,   9635.00),
( 9, 20240312, 1, 4,  2,  5499.00,    0.00,  10998.00,  10998.00),
(10, 20240401, 2, 5,  4,   799.00,    0.00,   3196.00,   3196.00),
(11, 20240415, 3, 1,  1, 29990.00,    0.00,  29990.00,  29990.00),
(12, 20240501, 4, 2,  6,  2999.00,  300.00,  17994.00,  17694.00),
(13, 20240610, 5, 3, 20,   649.00,    0.00,  12980.00,  12980.00),
(14, 20240610, 1, 4,  3,  5499.00, 1000.00,  16497.00,  15497.00),
(15, 20240610, 2, 5,  2,   799.00,    0.00,   1598.00,   1598.00);
