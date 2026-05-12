# Advanced SQL and Data Warehousing — Week 2

Snowflake data warehouse setup and SQL analytics on fitness gym check-in, member, and location data

## Assignment Overview

Week 2 assignment for the Advanced SQL and Data Warehousing course (GB746) at UW–Madison. The goal was to ingest fitness gym data from S3 into Snowflake, run analytical queries to surface operational and membership insights, and demonstrate Snowflake's Time Travel feature to recover from an erroneous data modification.

## What's Included

| File | Description |
|---|---|
| `GB746_Assignment_2_Snowflake_Queries_Schlichtmann_T.sql` | Full SQL script covering warehouse setup, data loading, aggregations, window functions, and Time Travel table restoration |
| `GB746_Assignment_2_Gym_Visits_by_Hour_of_Day_Line_Chart_Schlichtmann_T.xlsx` | Excel file with exported query results and a formatted line chart of visits by hour of day |

## Skills Demonstrated

- Creating Snowflake virtual warehouses, databases, and tables
- Defining external stages and file formats to load CSV data from S3
- Aggregation and filtering queries (`GROUP BY`, `WHERE`, `COUNT`, `SUM`)
- Window functions for running totals, lag comparisons, and ranked results (`SUM OVER`, `LAG`, `RANK`)
- CTEs for multi-step analytical logic
- Multi-table joins between check-in, member, and gym data
- Business analysis: gym inventory by city, membership growth over time, peak visit hours, off-hours staffing coverage
- Snowflake Time Travel to restore a table to a pre-modification state

## Key Findings

- **417 total gyms** across 10 cities; top cities by count: Boston, Chicago, Dallas, Denver
- **14 gyms** are staffed 24/7
- Largest member age group: **25–34** (~100k members); membership skews younger
- Membership grew from **133,798** (Dec 2023) to **299,370** (Jun 2025)
- Busiest check-in periods: **Early Morning (5–7 AM)** and **Dinner Time (4–7 PM)**
- **Less than 1%** of visits occurred outside staffed hours
- Check-in data spans **2025-01-01 to 2025-08-28**
