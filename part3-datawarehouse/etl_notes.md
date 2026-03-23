# Part 3 — ETL Notes

## ETL Decisions

### Decision 1 — Standardizing Inconsistent Date Formats

**Problem:** The `retail_transactions.csv` dataset contained transaction dates in at least three different formats across rows: `DD/MM/YYYY` (e.g., `15/01/2024`), `YYYY-MM-DD` (e.g., `2024-02-05`), and `DD-Mon-YY` (e.g., `20-Feb-24`). Loading these raw strings into a DATE column would either cause type errors or silently coerce dates incorrectly (e.g., `05/01/2024` interpreted as May 1st instead of January 5th).

**Resolution:** During the transformation stage, all date strings were parsed using Python's `dateutil.parser.parse()` with explicit format detection, then uniformly serialized to ISO 8601 format (`YYYY-MM-DD`) before insertion. A surrogate `date_key` in `YYYYMMDD` integer format was derived from the clean date to serve as the primary key in `dim_date`, enabling fast integer joins in the warehouse rather than string-based date comparisons.

---

### Decision 2 — Normalizing Inconsistent Category Casing

**Problem:** The `category` column in the raw CSV contained the same category spelled in multiple ways: `"electronics"`, `"ELECTRONICS"`, `"Electronics"`, and even `"electroniCs"`. Grouping or filtering by category in analytical queries without cleaning would produce fragmented results — e.g., monthly revenue for Electronics would be split across four separate rows instead of one.

**Resolution:** All category values were transformed to Title Case using `str.title()` in Python during the staging phase. A lookup table of expected categories (`Electronics`, `Clothing`, `Groceries`, `Footwear`, `Kitchenware`) was used to validate cleaned values; any unrecognized category was flagged for manual review rather than silently inserted, preventing future drift. The standardized values are stored in `dim_product.category`.

---

### Decision 3 — Handling NULL Values in Revenue-Critical Columns

**Problem:** Several rows in `retail_transactions.csv` contained NULL (or empty string) values in `quantity` and `unit_price` — the two columns used to compute `gross_revenue` and `net_revenue` in the fact table. Inserting these rows as-is would produce NULL measures in the fact table, silently excluding those transactions from SUM aggregations and causing revenue totals to be understated.

**Resolution:** Three strategies were applied based on the nature of the NULL: (1) Rows with NULL `quantity` were dropped from the load — a missing quantity means the transaction volume is unknown and cannot be imputed safely. (2) Rows with NULL `unit_price` were joined against `dim_product` on `product_id` to back-fill the price from the dimension table's `unit_price` column, which is always populated. (3) A data quality log was written during ETL recording the count of dropped rows and back-filled prices per load date, enabling the data engineering team to trace anomalies back to their source system.
