# Advanced SQL and Data Warehousing — Week 2

Snowflake data warehouse setup and SQL analytics on fitness gym check-in, member, and location data.

---

## Overview

This project sets up a Snowflake data warehouse for a fitness gym chain and runs a series of analytical queries to surface operational and membership insights. Data is loaded from an S3 stage into three tables — gyms, members, and check-ins — and queried using aggregations, window functions, and joins. The project also demonstrates Snowflake's Time Travel feature to recover from an erroneous data modification.

---

## Tools & Technologies

- **Snowflake** — cloud data warehouse, virtual warehouses, stages, file formats, Time Travel
- **SQL** — DDL, DML, aggregations, joins, window functions (RANK, SUM, LAG), CTEs
- **AWS S3** — external stage for source data files
- **Microsoft Excel** — exported query results and line chart visualization

---

## Data Model

Three tables loaded from pipe-delimited CSV files staged in S3:

| Table | Key Columns | Rows |
|---|---|---|
| `gyms` | gym_id, city, region, size, staff_open_hour, staff_close_hour, daily_capacity_hint | 417 |
| `members` | member_id, home_gym_id, age_group, membership_type, join_date | ~300k |
| `checkins` | checkin_id, member_id, gym_id, checkin_datetime | Millions |

---

## Warehouse Setup

Two separate virtual warehouses were created to isolate loading from querying workloads:

```sql
CREATE OR REPLACE WAREHOUSE fitness_loading_wh
  WITH WAREHOUSE_SIZE = 'SMALL' AUTO_RESUME = TRUE AUTO_SUSPEND = 600 INITIALLY_SUSPENDED = TRUE;

CREATE OR REPLACE WAREHOUSE fitness_querying_wh
  WITH WAREHOUSE_SIZE = 'SMALL' AUTO_RESUME = TRUE AUTO_SUSPEND = 600 INITIALLY_SUSPENDED = TRUE;
```

Data was loaded via an external S3 stage with a custom pipe-delimited file format.

---

## Key Queries & Findings

### Gym Inventory
- **417 total gyms** across 10 cities
- Top 4 cities by gym count: **Boston, Chicago, Dallas, Denver**
- **14 gyms** are staffed 24/7 (staff_open_hour = 0, staff_close_hour = 24)

### Membership Demographics
- Largest age group: **25–34** (~100k members)
- Distribution descends with age: 35–44 (~80k), 18–24 (~57k), 45–54 (~48k), 55+ (~33k)

### Membership Growth (Window Function)
Running total calculated using `SUM() OVER (ORDER BY month ROWS UNBOUNDED PRECEDING)`:

| Period | Running Total Members |
|---|---|
| Dec 2023 | 133,798 |
| Jun 2024 | 250,164 |
| Dec 2024 | 287,673 |
| Jun 2025 | 299,370 |

### Check-In Data Range
- **Earliest:** 2025-01-01
- **Latest:** 2025-08-28

### Visits by Hour of Day
- Busiest periods: **Early Morning (5–7 AM)** and **Dinner Time (4–7 PM)**
- Results exported to Excel and visualized as a line chart

### Visits Outside Staffed Hours
- Less than **1% of total visits** occurred outside staffed hours
- Calculated using a `CASE` expression with `EXTRACT('hour', ...)` joined against each gym's open/close hours

### Top 100 Gyms by Off-Hours Visits (Window Function)
Ranked using `RANK() OVER (ORDER BY COUNT(*) DESC)` with gap handling for ties:

| Gym | City | Rank |
|---|---|---|
| G0079 | Houston | 1 |
| G0270 | Los Angeles | 3 |
| G0370 | Pittsburgh | 9 |
| G0047 | San Jose | 15 |
| G0299 | St. Louis | 20 |

---

## Time Travel — Table Restoration

A junior analyst accidentally updated all `standard` memberships to `plus` (234,912 rows affected). The table was restored to its pre-update state using Snowflake's Time Travel feature:

```sql
CREATE OR REPLACE TABLE members AS (
  SELECT * FROM members BEFORE (
    STATEMENT => '01c1fa66-0004-548b-0000-000b27ea2ba9'
  )
);
```

---

## Files

| File | Description |
|---|---|
| `GB746_Assignment_2_Snowflake_Queries_Schlichtmann_T.sql` | Full SQL script: warehouse setup, data loading, and all analytical queries |
| `GB746_Assignment_2_Gym_Visits_by_Hour_of_Day_Line_Chart_Schlichtmann_T.xlsx` | Excel file with exported query results and formatted line chart |

---

## Results

Scored **5.5 / 6 (91.7%)** on the graded assignment.
