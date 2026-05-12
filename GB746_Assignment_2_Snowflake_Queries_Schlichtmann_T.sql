-- Setting role as sysadmin
USE ROLE sysadmin;
-- Creating a new warehouse for loading data and a warehouse for querying data.
CREATE
OR REPLACE WAREHOUSE fitness_loading_wh WITH WAREHOUSE_SIZE = 'SMALL' AUTO_RESUME = TRUE AUTO_SUSPEND = 600 INITIALLY_SUSPENDED = TRUE;
CREATE
OR REPLACE WAREHOUSE fitness_querying_wh WITH WAREHOUSE_SIZE = 'SMALL' AUTO_RESUME = TRUE AUTO_SUSPEND = 600 INITIALLY_SUSPENDED = TRUE;
-- Creating a new database called fitness
CREATE DATABASE IF NOT EXISTS fitness;
USE WAREHOUSE fitness_loading_wh;
-- Creating tables where data will be loaded
CREATE
OR REPLACE TABLE gyms (
    gym_id string,
    city string,
    region string,
    size string,
    staff_open_hour integer,
    staff_close_hour integer,
    daily_capacity_hint integer
);
CREATE
OR REPLACE TABLE members (
    member_id string,
    home_gym_id string,
    age_group string,
    membership_type string,
    join_date date
);
CREATE
OR REPLACE TABLE checkins (
    checkin_id string,
    member_id string,
    gym_id string,
    checkin_datetime timestamp
);
-- Creating a stage to access the data files
CREATE
OR REPLACE STAGE fitness_stage url = 's3://fitness-4285/';
LIST @fitness_stage;
DESCRIBE STAGE fitness_stage;
-- Creating file format
CREATE
OR REPLACE FILE FORMAT fitness_csv type = 'csv' compression = 'auto' field_delimiter = '|' record_delimiter = '\n' skip_header = 1 trim_space = false null_if = ('-') timestamp_format = 'auto' field_optionally_enclosed_by = '\042' -- strings could optionally be enclosed by ""
error_on_column_count_mismatch = false;
-- Confirming file format was created
SHOW FILE FORMATS IN DATABASE fitness;
-- Loading data into tables and checking data was properly loaded
COPY INTO gyms
FROM
    @fitness_stage/gyms file_format = fitness_csv;
COPY INTO members
FROM
    @fitness_stage/members file_format = fitness_csv;
COPY INTO checkins
FROM
    @fitness_stage/checkins file_format = fitness_csv;
SELECT
    COUNT(*)
FROM
    gyms;
SELECT
    *
FROM
    gyms
LIMIT
    10;
SELECT
    COUNT(*)
FROM
    members;
SELECT
    *
FROM
    members
LIMIT
    10;
SELECT
    COUNT(*)
FROM
    checkins;
SELECT
    *
FROM
    checkins
LIMIT
    10;
-- Querying data
    USE WAREHOUSE fitness_querying_wh;
-- total count of gyms
SELECT
    COUNT(gym_id) AS total_gym_count
FROM
    gyms;
-- count of gyms in each city
SELECT
    city,
    COUNT(gym_id) AS total_gym_count
FROM
    gyms
GROUP BY
    city
ORDER BY
    total_gym_count DESC;
-- count of gyms staffed 24/7
SELECT
    COUNT(gym_id) AS total_gym_count
FROM
    gyms
WHERE
    staff_open_hour = 0
    AND staff_close_hour = 24;
-- count of members in each age group
SELECT
    age_group,
    COUNT(member_id) AS member_count
FROM
    members
GROUP BY
    age_group
ORDER BY
    age_group;
-- membership growth with a running total by year and month
SELECT
    DATE_TRUNC('month', join_date) AS month,
    COUNT(*) AS member_count,
    LAG(member_count) OVER (
        ORDER BY
            month
    ) AS previous_member_count,
    SUM(member_count) OVER (
        ORDER BY
            month ROWS UNBOUNDED PRECEDING
    ) AS running_total_membership_count
FROM
    members
GROUP BY
    month
ORDER BY
    month;
-- date range of checkin data
SELECT
    MIN(checkin_datetime) AS earliest_checkin_date,
    MAX(checkin_datetime) AS latest_checkin_date
FROM
    checkins;
-- count of total visits by hour of the day
SELECT
    EXTRACT('hour', checkin_datetime) AS hour_of_checkin,
    COUNT(*) AS visit_count
FROM
    checkins
GROUP BY
    hour_of_checkin
ORDER BY
    hour_of_checkin;
-- percentage of visits outside of staffed hours
SELECT
    SUM(
        CASE
            WHEN EXTRACT('hour', c.checkin_datetime) NOT BETWEEN g.staff_open_hour
            AND g.staff_close_hour THEN 1
            ELSE 0
        END
    ) AS outside_staff_hours,
    COUNT(*) AS total_visits,
    (
        SUM(
            CASE
                WHEN EXTRACT('hour', c.checkin_datetime) NOT BETWEEN g.staff_open_hour
                AND g.staff_close_hour THEN 1
                ELSE 0
            END
        ) / COUNT(*)
    ) * 100 AS percent_outside_staff_hours
FROM
    checkins c
    JOIN gyms g ON g.gym_id = c.gym_id;
-- top 100 gyms with the most visits outside of staffed hours
    WITH ranked AS (
        SELECT
            g.gym_id,
            COUNT(*) AS outside_staff_visits,
            RANK() OVER (
                ORDER BY
                    COUNT(*) DESC
            ) AS gym_rank
        FROM
            checkins c
            JOIN gyms g ON g.gym_id = c.gym_id
        WHERE
            EXTRACT('hour', c.checkin_datetime) NOT BETWEEN g.staff_open_hour
            AND g.staff_close_hour
        GROUP BY
            g.gym_id
    )
SELECT
    *
FROM
    ranked
ORDER BY
    gym_rank
LIMIT
    100;
    -- restoring a table
UPDATE
    members
SET
    membership_type = 'plus'
WHERE
    membership_type = 'standard';
SELECT
    COUNT(membership_type) AS membership_type_count
FROM
    members
WHERE
    membership_type = 'plus';
CREATE
    OR REPLACE TABLE members AS (
        SELECT
            *
        FROM
            members before (
                statement => '01c1fa66-0004-548b-0000-000b27ea2ba9'
            )
    );
SELECT
    COUNT(membership_type) AS membership_type_count
FROM
    members
WHERE
    membership_type = 'plus';

-- troubleshooting quiz questions marked incorrect 
SELECT
    COUNT(*),
    CASE
        WHEN EXTRACT('hour', c.checkin_datetime) BETWEEN g.staff_open_hour
        AND g.staff_close_hour THEN 'in staff hours'
        ELSE 'outside staff hours'
    END AS in_staff_hours
FROM
    checkins c
    JOIN gyms g ON g.gym_id = c.gym_id
GROUP BY
    in_staff_hours;
SELECT
    gym_id,
    staff_open_hour,
    staff_close_hour
FROM
    gyms
WHERE
    gym_id IN ('G0079', 'G0270', 'G0370', 'G0047', 'G0299');
WITH ranked AS (
        SELECT
            g.gym_id,
            COUNT(*) AS outside_staff_visits,
            RANK() OVER (
                ORDER BY
                    COUNT(*) DESC
            ) AS gym_rank
        FROM
            checkins c
            JOIN gyms g ON g.gym_id = c.gym_id
        WHERE
            EXTRACT('hour', c.checkin_datetime) < g.staff_open_hour
            OR EXTRACT('hour', c.checkin_datetime) > g.staff_close_hour
        GROUP BY
            g.gym_id
    )
SELECT
    *
FROM
    ranked
WHERE
    gym_id IN ('G0079', 'G0270', 'G0370', 'G0047', 'G0299')
ORDER BY
    gym_rank;
WITH ranked AS (
        SELECT
            g.gym_id,
            COUNT(*) AS outside_staff_visits,
            RANK() OVER (
                ORDER BY
                    COUNT(*) DESC
            ) AS gym_rank
        FROM
            checkins c
            JOIN gyms g ON g.gym_id = c.gym_id
        WHERE
            EXTRACT('hour', c.checkin_datetime) NOT BETWEEN g.staff_open_hour
            AND g.staff_close_hour - 1
        GROUP BY
            g.gym_id
    )
SELECT
    gym_id,
    gym_rank
FROM
    ranked
WHERE
    gym_id IN ('G0079', 'G0270', 'G0370', 'G0047', 'G0299')
ORDER BY
    gym_rank;
