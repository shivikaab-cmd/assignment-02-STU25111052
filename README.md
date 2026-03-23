
 Overall Data Flow Architecture

```mermaid
graph TD
A[Raw Data Sources] --> B[Data Cleaning and Transformation]
B --> C[RDBMS Normalized Tables]
C --> D[Data Warehouse Star Schema]
D --> E[Analytical Queries BI]

A --> F[NoSQL MongoDB]
A --> G[Data Lake DuckDB]

E --> H[Insights and Reports]

A --> I[Vector DB Embeddings]
I --> J[Semantic Search Similarity]

'''

Part 1 - RDBMS (Normalization and SQL)
Working with relational databases helped me understand the importance of structured data design. Initially, storing everything in one table seemed simple, but it quickly became clear how it leads to redundancy and inconsistencies.
By applying normalization (up to 3NF), I learned how to break down data into logical entities such as customers, orders, and products. This not only reduced duplication but also ensured data integrity.
Writing SQL queries improved my ability to extract meaningful insights from structured data. I also realized how joins play a critical role in combining normalized tables efficiently.

Part 2 - NoSQL (MongoDB)
This part completely changed my perspective on data storage. Unlike relational databases, MongoDB allows flexible schemas, which is very useful when dealing with diverse or evolving data.
I learned how to design JSON documents that reflect real-world entities more naturally. Nested structures and arrays helped in storing complex relationships without the need for joints
The comparison between RDBMS and NoSQL made it clear that NoSQL is better suited for scalability and flexibility, while RDBMS is better for consistency and structured data.

Part 3 - Data Warehouse (Star Schema)
Designing a star schema helped me understand how analytical systems differ from transactional systems. Instead of normalization, the focus here is on performance and query efficiency.
I created fact and dimension tables, which made it easier to perform aggregations like total sales and trends. This part also highlighted the importance of clean and consistent data through ETL processes.
I realized how businesses rely on data warehouses for decision-making and reporting.

Part 4 - Vector Database (Embeddings)
This was the most interesting and new concept for me. I learned how text can be converted into numerical vectors using embeddings.
By computing cosine similarity, I could find sentences that are semantically similar, not just keyword-matching. This is very powerful for applications like search engines and recommendation systems.
It gave me exposure to how AI systems understand meaning rather than exact words.

Part 5 - Data Lake & DuckDB
This part showed how modern systems handle large volumes of raw data in multiple formats like CSV, JSON, and Parquet.
Using DuckDB, I was able to query these files directly without loading them into a database. This demonstrated the flexibility and efficiency of data lakes.
I also understood why organizations prefer data lakes for storing raw and unstructured data.

Part 6 - Capstone (System Design)
The capstone brought everything together. I designed an end-to-end system for a hospital use case, combining real-time data ingestion, storage, analytics, and AI.
This helped me understand how different systems (OLTP, OLAP, streaming, AI models) interact in a real-world architecture.
I also learned about trade-offs such as performance vs complexity and how to justify design decisions.


Final Reflection
This assignment gave me a holistic understanding of modern data ecosystems. It helped me move beyond theoretical knowledge and apply concepts practically.
I now understand that:
No single database fits all use cases
System design depends on data type and requirements
Data engineering is about choosing the right tools for the problem

Overall, this assignment significantly strengthened my foundation in data engineering and analytics.
