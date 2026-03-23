# Part 6 — Capstone Architecture Design

## Architecture Diagram Description

The hospital data system flows through six layers. Reading left to right:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DATA SOURCES (Layer 1)                              │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐   │
│  │  ICU Vitals  │ │  EHR System  │ │  Lab Results │ │  Admission /     │   │
│  │  Monitors    │ │  (HL7/FHIR)  │ │  (CSV/API)   │ │  Billing System  │   │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └────────┬─────────┘   │
└─────────┼────────────────┼────────────────┼──────────────────┼─────────────┘
          │                │                │                  │
          ▼                ▼                ▼                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     INGESTION LAYER (Layer 2)                               │
│         ┌──────────────────────┐       ┌──────────────────────┐             │
│         │   Apache Kafka       │       │   Batch ETL Pipeline │             │
│         │   (Real-time stream) │       │   (Apache Airflow)   │             │
│         └──────────┬───────────┘       └──────────┬───────────┘             │
└────────────────────┼──────────────────────────────┼─────────────────────────┘
                     │                              │
          ┌──────────┴───────┐           ┌──────────┴───────┐
          ▼                  ▼           ▼                  ▼
┌─────────────────┐ ┌────────────────────────────────────────────┐
│  OLTP LAYER     │ │              DATA LAKE (Layer 3)            │
│  (Layer 3a)     │ │  AWS S3 / Azure ADLS  — Delta Lake format  │
│                 │ │  Raw zone → Cleaned zone → Curated zone     │
│  PostgreSQL     │ └────────────────────────┬───────────────────┘
│  (Patient       │                          │
│  records,       │              ┌───────────┴───────────┐
│  admissions,    │              ▼                       ▼
│  prescriptions) │  ┌────────────────────┐  ┌──────────────────────┐
│                 │  │  OLAP / DW Layer   │  │  Vector Database     │
│  ACID, row-     │  │  (Layer 4)         │  │  (Layer 5)           │
│  store, FK      │  │                    │  │                      │
│  constraints    │  │  Snowflake /       │  │  Pinecone / pgvector │
└────────┬────────┘  │  Amazon Redshift   │  │  (Patient history    │
         │           │  star schema for   │  │  embeddings for      │
         │           │  BI reporting      │  │  plain-English       │
         │           └────────┬───────────┘  │  doctor queries)     │
         │                    │              └──────────┬───────────┘
         │                    ▼                         │
         │        ┌────────────────────────┐            │
         │        │   ANALYTICS LAYER      │            │
         │        │   (Layer 6)            │◄───────────┘
         │        │                        │
         │        │  Power BI / Tableau    │
         │        │  (Monthly reports:     │
         │        │  occupancy, dept cost) │
         │        │                        │
         │        │  ML Platform (SageMaker│
         │        │  / Vertex AI):         │
         │        │  Readmission risk model│
         └───────►└────────────────────────┘
```

**Flow narrative:** ICU monitors stream vitals to Kafka in real time. The EHR, lab, and billing systems batch-load via Airflow into PostgreSQL (OLTP) for day-to-day clinical operations. Simultaneously, all data lands in a Delta Lake on cloud object storage. The curated zone feeds two downstream systems: (1) a Snowflake/Redshift data warehouse for monthly management reports and (2) a vector database that stores embeddings of patient history notes, enabling doctors to query in plain English. The ML platform trains readmission models on the data warehouse's historical feature tables and serves predictions back to clinicians via an API.

---

## Storage Systems

**Goal 1 — Predict patient readmission risk:** Historical treatment data (diagnoses, procedures, length of stay, prior admissions) is stored in the **Snowflake data warehouse** in a star schema. Feature engineering pipelines (Spark/dbt) compute aggregate features per patient encounter and materialize them as wide feature tables. The ML model (XGBoost or a Transformer-based model) is trained on these features using Amazon SageMaker. Snowflake is chosen because it natively handles petabyte-scale analytical queries, supports time-travel for auditing model training datasets, and integrates directly with SageMaker via the Snowflake ML connector.

**Goal 2 — Plain-English doctor queries:** All clinical notes, discharge summaries, and treatment records are embedded using a medical language model (`Bio_ClinicalBERT`) and stored in a **vector database** (Pinecone or pgvector extension on PostgreSQL). A doctor's query is embedded at runtime, and cosine similarity search retrieves the top-k relevant patient history passages. A retrieval-augmented generation (RAG) layer then passes those passages to an LLM (GPT-4 / Claude) to generate a structured, cited answer.

**Goal 3 — Monthly management reports:** The **Snowflake data warehouse** (same instance as Goal 1) hosts `fact_admissions`, `dim_department`, `dim_bed`, and `fact_cost` tables. Power BI or Tableau connects via Snowflake's native connector and pre-built dashboards deliver bed occupancy rates, department-wise cost breakdowns, and staff utilization metrics on a scheduled refresh.

**Goal 4 — Real-time ICU vitals:** A dedicated **Apache Kafka** cluster ingests telemetry from ICU monitors (heart rate, SpO2, blood pressure) at sub-second latency. Apache Flink processes the stream, applies threshold-based alerting rules (e.g., SpO2 < 92% for > 30 seconds triggers a nurse alert), and simultaneously writes raw telemetry to the Delta Lake raw zone for long-term archival and retrospective ML training.

---

## OLTP vs OLAP Boundary

The **OLTP boundary** is defined at the PostgreSQL operational database. This system handles all real-time clinical transactions: patient admissions, medication orders, discharge processing, appointment scheduling, and billing entries. It is optimized for concurrent row-level writes, enforces referential integrity via foreign keys, and supports ACID transactions critical for patient safety (e.g., preventing double-dispensing of medications).

The **OLAP boundary** begins at the Snowflake data warehouse, which is populated by nightly Airflow ETL jobs that extract changed records from PostgreSQL, transform them into dimensional model format, and load them into star schema tables. The data warehouse is read-only from the analytics perspective — no clinical workflows write to it directly. This separation ensures that heavy analytical queries (e.g., "show me 5 years of readmission data aggregated by DRG code") never compete with life-critical clinical writes for database resources.

The Delta Lake serves as the staging ground between the two: raw data lands here first, is cleaned and validated, then forked — refreshed back into PostgreSQL corrections if needed, or forwarded to Snowflake for analytical consumption.

---

## Trade-offs

**Primary Trade-off: Data Freshness vs. Query Performance**

The nightly ETL pattern between PostgreSQL and Snowflake means the data warehouse is always 12–24 hours stale. For monthly management reports, this is acceptable. However, if clinicians want near-real-time department occupancy dashboards (e.g., "how many ICU beds are free right now?"), the nightly batch cycle fails them.

**Mitigation strategy:** Implement **incremental streaming ETL** using Debezium (CDC — Change Data Capture) on the PostgreSQL WAL log, feeding changed rows into Kafka, and processing them with Flink into Snowflake via Snowpipe. This reduces latency from 24 hours to under 5 minutes for operational metrics while keeping the architectural separation of OLTP and OLAP intact. For the specific case of bed occupancy, a lightweight Redis cache updated by Kafka consumers can serve sub-second reads without touching the warehouse at all. The trade-off then shifts to increased infrastructure complexity and operational cost — which is justified for a hospital network where real-time situational awareness directly affects patient outcomes.
