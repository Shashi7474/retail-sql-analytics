# Retail Sales Analytics — SQL Project

A complete, runnable SQL data analytics project: a normalized retail database, realistic sample data, a query library covering the full range of SQL skills, and analytical use cases ready to feed a BI dashboard.

## Why this project
Demonstrates database design (normalization, keys, constraints), core and advanced SQL (joins, subqueries, window functions, CTEs), and translating queries into business insight — the exact skill set for a data analyst role, and a natural pairing with Power BI dashboards.

## Structure
```
sql-retail-analytics/
├── sql/
│   ├── 01_schema.sql                 # Table definitions (MySQL syntax)
│   ├── 02_analytical_queries.sql     # 15 business queries, basic → advanced
│   └── 03_views_and_procedures.sql   # Views + stored procedures (MySQL)
├── data/
│   ├── retail_analytics_demo.db      # Pre-built SQLite demo database (ready to query)
│   └── *.csv                         # Same data as CSVs, for loading into any DB
├── generate_data.py                  # Regenerate the sample dataset (Faker-based)
└── README.md
```

## Schema
7 tables: `customers`, `stores`, `employees` (self-referencing manager relationship), `categories`, `products`, `orders`, `order_items` (bridge table for the orders↔products many-to-many). Fully normalized to 3NF with primary/foreign keys, `CHECK` constraints, and indexes on the columns analytical queries filter/join on most.

## Sample data
Generated with Faker, seeded for reproducibility:
- 800 customers · 5 stores · 27 employees · 7 categories · 35 products
- 4,000 orders · ~12,000 order line items
- Spans 2023–2026, includes Completed/Cancelled/Returned statuses

## Quick start

**Option A — SQLite (already built, zero setup)**
```bash
sqlite3 data/retail_analytics_demo.db
.read sql/02_analytical_queries.sql
```

**Option B — MySQL (recommended for the full project incl. views/procedures)**
```bash
mysql -u root -p < sql/01_schema.sql
# Load data/*.csv via LOAD DATA INFILE, or re-run generate_data.py against MySQL
mysql -u root -p your_db < sql/03_views_and_procedures.sql
```

**Regenerate data** (edit volumes/seed in `generate_data.py` first if you want a bigger dataset):
```bash
pip install faker
python3 generate_data.py
```

## What the query library covers
| # | Concept | Business question |
|---|---|---|
| 1 | Multi-table JOIN + GROUP BY | Top 10 highest-value orders |
| 2 | 3-table JOIN | Revenue by category |
| 3 | LEFT JOIN | Customers who never ordered |
| 4 | SELF JOIN | Employee → manager hierarchy |
| 5 | GROUP BY + HAVING | High-volume stores |
| 6 | Subquery | Above-average priced products |
| 7 | Correlated subquery | Price rank within category |
| 8 | CTE + window (LAG) | Month-over-month revenue growth |
| 9 | Window (RANK, PARTITION BY) | Top products per category |
| 10 | Window (running SUM) | Cumulative revenue over time |
| 11 | Multi-join aggregation | Customer lifetime value |
| 12 | CTE + date math | Churn risk (90+ days inactive) |
| 13 | RFM segmentation | Recency/Frequency/Monetary tiers |
| 14 | Profit margin analysis | Most/least profitable products |
| 15 | Conditional aggregation | Return/cancellation rate by store |

## Connecting to Power BI
Point Power BI's MySQL connector at your loaded database and build visuals directly on top of the three views in `03_views_and_procedures.sql` (`monthly_sales_summary`, `customer_lifetime_value`, `product_profitability`) — this keeps your dashboard's DAX layer thin since the heavy aggregation already happens in SQL.

## Suggested next steps
- Push to GitHub with the ER diagram in the README for a strong portfolio piece
- Swap in a real dataset (Kaggle e-commerce, or your own domain — healthcare, agriculture) using the same schema pattern
- Add a `triggers.sql` file (e.g. auto-update inventory on order placement) to show more advanced DB features
