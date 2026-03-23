-- ============================================================
-- PART 1: RDBMS Schema Design
-- File: part1-rdbms/schema_design.sql
-- Source Dataset: orders_flat.csv
-- ============================================================
--
-- ORIGINAL orders_flat.csv COLUMN STRUCTURE (flat / denormalized):
-- ┌────────────────────────────────────────────────────────────┐
-- │ order_id   | customer_name | customer_email | city        │
-- │ state      | product_name  | category       | quantity    │
-- │ unit_price | total_amount  | order_date     | status      │
-- │ sales_rep  | region                                       │
-- └────────────────────────────────────────────────────────────┘
--
-- SAMPLE ROWS FROM orders_flat.csv (raw):
--  order_id | customer_name   | city    | product_name        | qty | unit_price | total_amount | sales_rep    | region
--  1001     | Alice Fernandez | Mumbai  | Wireless Headphones |  2  |  2999.00   |   5998.00    | Rohan Mehta  | West
--  1002     | Bob Verma       | Delhi   | Basmati Rice 5kg    |  5  |   350.00   |   1750.00    | Priya Sharma | North
--  1003     | Alice Fernandez | Mumbai  | Cotton T-Shirt      |  3  |   499.00   |   1497.00    | Rohan Mehta  | West  ← UPDATE ANOMALY
--  1004     | Carol Singh     | Bengaluru| Running Shoes      |  1  |  1899.00   |   1899.00    | Arjun Nair   | South
--  1005     | David Patel     | Ahmedabad| Stainless Pan      |  2  |   799.00   |   1598.00    | Vikram Joshi | North ← DELETE ANOMALY
--
-- NORMALIZATION MAPPING (orders_flat.csv → 3NF tables):
--  customer_name, city, state, customer_email  →  customers table
--  sales_rep, region                           →  sales_reps table
--  product_name, category, unit_price          →  products table
--  order_id, order_date, status                →  orders table  (FK → customers, sales_reps)
--  order_id, product_name, quantity, price     →  order_items table (FK → orders, products)
--
-- ============================================================
-- SECTION A: ANOMALY IDENTIFICATION (Comments)
-- ============================================================

-- INSERT ANOMALY:
-- In the flat orders_flat table, we cannot add a new customer
-- unless they have placed at least one order. Customer details
-- (name, city) are tied to order rows, so inserting a customer
-- with no orders is impossible without storing NULLs in order columns.

-- UPDATE ANOMALY:
-- If a customer moves to a new city, every row in orders_flat
-- containing that customer must be updated. Missing even one row
-- causes inconsistent data (e.g., "Alice" appears in both
-- "Mumbai" and "Delhi" across different order rows).

-- DELETE ANOMALY:
-- Deleting the only order placed by a sales rep removes all
-- knowledge of that sales rep from the database. Sales rep
-- information is not stored independently; it exists only
-- within order rows.

-- ============================================================
-- SECTION B: NORMALIZED SCHEMA (3NF)
-- ============================================================

-- Drop tables in reverse dependency order (safe re-run)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS sales_reps;

-- ----------------------------------------------------------
-- Table: sales_reps
-- Dependency: none
-- ----------------------------------------------------------
CREATE TABLE sales_reps (
    rep_id       INTEGER      PRIMARY KEY,
    rep_name     VARCHAR(100) NOT NULL,
    region       VARCHAR(50)  NOT NULL,
    email        VARCHAR(150) NOT NULL UNIQUE
);

INSERT INTO sales_reps (rep_id, rep_name, region, email) VALUES
(1, 'Rohan Mehta',   'West',  'rohan.mehta@retailco.com'),
(2, 'Priya Sharma',  'North', 'priya.sharma@retailco.com'),
(3, 'Arjun Nair',    'South', 'arjun.nair@retailco.com'),
(4, 'Sneha Kulkarni','East',  'sneha.kulkarni@retailco.com'),
(5, 'Vikram Joshi',  'North', 'vikram.joshi@retailco.com');

-- ----------------------------------------------------------
-- Table: customers
-- Dependency: none
-- ----------------------------------------------------------
CREATE TABLE customers (
    customer_id   INTEGER      PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    city          VARCHAR(80)  NOT NULL,
    state         VARCHAR(80)  NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE
);

INSERT INTO customers (customer_id, customer_name, city, state, email) VALUES
(101, 'Alice Fernandez', 'Mumbai',    'Maharashtra', 'alice.f@gmail.com'),
(102, 'Bob Verma',       'Delhi',     'Delhi',       'bob.verma@gmail.com'),
(103, 'Carol Singh',     'Bengaluru', 'Karnataka',   'carol.s@gmail.com'),
(104, 'David Patel',     'Ahmedabad', 'Gujarat',     'david.p@gmail.com'),
(105, 'Eva Nair',        'Chennai',   'Tamil Nadu',  'eva.nair@gmail.com');

-- ----------------------------------------------------------
-- Table: products
-- Dependency: none
-- ----------------------------------------------------------
CREATE TABLE products (
    product_id    INTEGER       PRIMARY KEY,
    product_name  VARCHAR(150)  NOT NULL,
    category      VARCHAR(80)   NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL CHECK (unit_price > 0)
);

INSERT INTO products (product_id, product_name, category, unit_price) VALUES
(201, 'Wireless Headphones', 'Electronics',  2999.00),
(202, 'Cotton T-Shirt',      'Clothing',      499.00),
(203, 'Basmati Rice 5kg',    'Groceries',     350.00),
(204, 'Running Shoes',       'Footwear',     1899.00),
(205, 'Stainless Steel Pan', 'Kitchenware',   799.00);

-- ----------------------------------------------------------
-- Table: orders
-- Dependency: customers, sales_reps
-- ----------------------------------------------------------
CREATE TABLE orders (
    order_id     INTEGER     PRIMARY KEY,
    customer_id  INTEGER     NOT NULL,
    rep_id       INTEGER     NOT NULL,
    order_date   DATE        NOT NULL,
    status       VARCHAR(30) NOT NULL DEFAULT 'Pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (rep_id)      REFERENCES sales_reps(rep_id)
);

INSERT INTO orders (order_id, customer_id, rep_id, order_date, status) VALUES
(3001, 101, 1, '2024-01-10', 'Delivered'),
(3002, 102, 2, '2024-01-15', 'Delivered'),
(3003, 103, 3, '2024-02-05', 'Shipped'),
(3004, 104, 4, '2024-02-20', 'Processing'),
(3005, 105, 5, '2024-03-01', 'Delivered'),
(3006, 101, 2, '2024-03-12', 'Delivered'),
(3007, 103, 1, '2024-03-18', 'Cancelled');

-- ----------------------------------------------------------
-- Table: order_items
-- Dependency: orders, products
-- ----------------------------------------------------------
CREATE TABLE order_items (
    item_id     INTEGER       PRIMARY KEY,
    order_id    INTEGER       NOT NULL,
    product_id  INTEGER       NOT NULL,
    quantity    INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price  DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO order_items (item_id, order_id, product_id, quantity, unit_price) VALUES
(1, 3001, 201, 2, 2999.00),
(2, 3001, 202, 3,  499.00),
(3, 3002, 203, 5,  350.00),
(4, 3002, 204, 1, 1899.00),
(5, 3003, 205, 2,  799.00),
(6, 3004, 201, 1, 2999.00),
(7, 3005, 202, 4,  499.00),
(8, 3005, 203, 2,  350.00),
(9, 3006, 204, 2, 1899.00),
(10,3007, 205, 1,  799.00);
