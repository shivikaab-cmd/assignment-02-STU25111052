# Part 5 — Data Lake Architecture

## Architecture Recommendation

**Recommended Architecture: Data Lakehouse**

For a fast-growing food delivery startup collecting GPS location logs, customer text reviews, payment transactions, and restaurant menu images, I recommend a **Data Lakehouse** architecture — specifically implemented using a platform such as Delta Lake on Databricks, or Apache Iceberg on AWS S3 with Athena.

**Reason 1 — Extreme Data Variety**
The startup generates four fundamentally different data types: structured (payment transactions), semi-structured (GPS logs as JSON), unstructured text (customer reviews), and binary objects (menu images). A traditional **Data Warehouse** cannot natively store unstructured blobs or semi-structured GPS traces without forcing them into rigid schemas — a process that loses information and slows ingestion. A pure **Data Lake** can store everything, but makes structured querying slow and unreliable. A **Data Lakehouse** stores raw data in open formats (Parquet, ORC, JSON) on cheap object storage (S3/GCS) while adding a metadata and transaction layer (Delta Lake / Iceberg) that enables SQL queries with ACID guarantees — getting the best of both worlds.

**Reason 2 — Multi-Workload Support from a Single Platform**
The startup needs: (a) real-time fraud scoring on payment streams, (b) ML model training on GPS + review data, (c) BI dashboards on transaction revenue. A Data Lakehouse serves all three without duplicating data. Tools like Spark Structured Streaming can read the same Delta tables for real-time scoring that dbt models use for BI reporting, eliminating costly ETL pipelines between a separate lake and warehouse.

**Reason 3 — Cost-Effective Scalability**
As the startup grows from thousands to millions of daily orders, object storage (S3) scales elastically at a fraction of the cost of a traditional data warehouse (Snowflake, BigQuery) at the same volume. The Lakehouse pattern allows the startup to pay only for compute when queries run, rather than maintaining always-on warehouse clusters — critical for a startup managing burn rate.
