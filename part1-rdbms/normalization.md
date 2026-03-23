# Part 1 — Normalization

## Anomaly Analysis

The following anomalies were identified in `orders_flat.csv`, which stores all orders, customers, products, and sales representative data in a single denormalized table.

### Original CSV Column Structure

`orders_flat.csv` contains these 14 columns in a single flat table:

| Column | Sample Value | Type |
|---|---|---|
| `order_id` | 1001 | Integer |
| `customer_name` | Alice Fernandez | String |
| `customer_email` | alice.f@gmail.com | String |
| `city` | Mumbai | String |
| `state` | Maharashtra | String |
| `product_name` | Wireless Headphones | String |
| `category` | Electronics | String |
| `quantity` | 2 | Integer |
| `unit_price` | 2999.00 | Decimal |
| `total_amount` | 5998.00 | Decimal |
| `order_date` | 2024-01-10 | Date |
| `status` | Delivered | String |
| `sales_rep` | Rohan Mehta | String |
| `region` | West | String |

All anomalies below refer to columns and rows from this structure.

### Insert Anomaly
**Problem:** A new sales representative cannot be added to the system unless they have already handled at least one order.
**Example from CSV:** If a new rep "Kavya Reddy" joins the North region but has not yet been assigned any orders, there is no row in `orders_flat.csv` to record her details. The `sales_rep` and `region` columns exist only within order rows (e.g., Row 1: `sales_rep = "Rohan Mehta"`, `region = "West"`). Inserting Kavya requires fabricating a dummy order, which pollutes the data.

### Update Anomaly
**Problem:** Changing a customer's city requires updating every row that contains that customer's name.
**Example from CSV:** "Alice Fernandez" appears in rows 1, 6, and 12 with `city = "Mumbai"`. If Alice moves to Pune, all three rows must be updated individually. If row 6 is missed, Alice simultaneously appears as living in both "Mumbai" and "Pune" — creating an inconsistency (rows: `order_id = 1001`, `order_id = 1006`, `order_id = 1012`, column: `city`).

### Delete Anomaly
**Problem:** Deleting the only order associated with a sales rep permanently destroys that rep's record.
**Example from CSV:** Rep "Vikram Joshi" appears only in row 5 (`order_id = 1005`, `sales_rep = "Vikram Joshi"`, `region = "North"`). If order 1005 is cancelled and deleted, all information about Vikram Joshi is lost — the system has no independent sales_rep table to preserve his record.

---

## Normalization Justification

A common managerial argument is that keeping all retail data in one flat table — as in `orders_flat.csv` — is simpler to manage and that normalization is over-engineering. This position, while understandable from a short-term operational perspective, is fundamentally flawed when examined against the reality of the dataset.

Consider the update anomaly identified above: "Alice Fernandez" appears in three separate rows because she placed multiple orders. Her city, "Mumbai", is duplicated across all three rows. The moment she relocates, a developer must write an `UPDATE` that touches every one of her rows. Miss even one row, and the query "List all customers from Mumbai" will return Alice in some queries but not others — a silent data corruption that is extremely difficult to debug in production.

Normalization directly solves this. By extracting customers into a `customers` table, Alice's city is stored exactly once. An `UPDATE customers SET city = 'Pune' WHERE customer_id = 101` is atomic, instantaneous, and guaranteed to be consistent across all orders.

The same argument applies to the delete anomaly. In the flat file, deleting order 1005 silently erases sales rep Vikram Joshi. This means management reports will undercount the rep roster, and commission calculations will be wrong — with zero indication that anything was deleted. In a normalized schema, deleting an order removes only the order row; the `sales_reps` table is untouched.

Critics of normalization often cite query complexity — joins are harder to write than a single `SELECT *`. This is true but misleading. The cost of a slightly more complex query is paid once, by a developer, at development time. The cost of an update anomaly is paid continuously, in wrong data, wrong reports, and lost business trust. Modern query optimizers handle multi-table joins efficiently, and views or ORM layers can abstract join complexity entirely.

In conclusion, normalization is not over-engineering — it is the minimum viable data integrity guarantee for any system that will be read, updated, or maintained beyond its first week.

---

## Column Mapping: orders_flat.csv → 3NF Tables

| Original CSV Column | Moved To | Reason |
|---|---|---|
| `customer_name`, `customer_email`, `city`, `state` | `customers` | Depends only on customer identity, not on any order |
| `sales_rep`, `region` | `sales_reps` | Depends only on the representative, not on any order |
| `product_name`, `category`, `unit_price` | `products` | Depends only on the product, not on any order |
| `order_id`, `order_date`, `status` | `orders` | Describes the transaction itself (FK to customer + rep) |
| `order_id` + `product_name` + `quantity` | `order_items` | Resolves the many-to-many between orders and products |
| `total_amount` | **Eliminated** | Computed value (`quantity × unit_price`) — storing it creates a transitive dependency, violating 3NF |

## Resulting Schema

| Table | Primary Key | Foreign Keys | CSV Columns Absorbed |
|---|---|---|---|
| `customers` | `customer_id` | — | `customer_name`, `city`, `state`, `customer_email` |
| `sales_reps` | `rep_id` | — | `sales_rep`, `region` |
| `products` | `product_id` | — | `product_name`, `category`, `unit_price` |
| `orders` | `order_id` | `customer_id`, `rep_id` | `order_id`, `order_date`, `status` |
| `order_items` | `item_id` | `order_id`, `product_id` | `quantity`, `unit_price` (price-at-time-of-sale snapshot) |
