-- ============================================================
--  Hospital Emergency Department — Performance Analysis
--  Author  : Iftekhar Bhuiyan
--  Dataset : hospital_ed_data.csv  (2,000 records, FY2024)
--  Engine  : MySQL / PostgreSQL compatible
-- ============================================================

-- ── SETUP (if importing into MySQL/PostgreSQL) ───────────────
/*
CREATE TABLE ed_admissions (
    patient_id          VARCHAR(10),
    admission_date      DATE,
    admission_time      TIME,
    day_of_week         VARCHAR(10),
    hour_of_day         INT,
    month               VARCHAR(15),
    month_num           INT,
    staff_shift         VARCHAR(30),
    age                 INT,
    age_group           VARCHAR(10),
    gender              VARCHAR(20),
    triage_category     INT,
    chief_complaint     VARCHAR(50),
    department          VARCHAR(30),
    wait_time_mins      INT,
    length_of_stay_hrs  DECIMAL(5,1),
    discharge_status    VARCHAR(30),
    bed_occupied        INT,
    readmitted_30_days  VARCHAR(3)
);
-- LOAD DATA INFILE 'hospital_ed_data.csv' INTO TABLE ed_admissions
--   FIELDS TERMINATED BY ',' IGNORE 1 ROWS;
*/


-- ============================================================
--  QUERY 1 — Executive KPI Summary
--  Business Question: How is the ED performing overall in FY2024?
-- ============================================================
SELECT
    COUNT(*)                                                    AS total_patients,
    ROUND(AVG(wait_time_mins), 1)                              AS avg_wait_mins,
    ROUND(MEDIAN(wait_time_mins), 1)                           AS median_wait_mins,   -- PostgreSQL
    -- ROUND(AVG(wait_time_mins), 1)                           -- use for MySQL
    ROUND(AVG(length_of_stay_hrs), 1)                          AS avg_los_hours,
    SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END)AS total_readmissions,
    ROUND(
        SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                                           AS readmission_rate_pct,
    SUM(CASE WHEN discharge_status = 'Left Without Being Seen'
             THEN 1 ELSE 0 END)                                AS lwbs_count,
    ROUND(
        SUM(CASE WHEN discharge_status = 'Left Without Being Seen'
                 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                                           AS lwbs_rate_pct,
    SUM(bed_occupied)                                           AS total_bed_days
FROM ed_admissions;


-- ============================================================
--  QUERY 2 — Wait Time by Triage Category
--  Business Question: Are higher-urgency patients seen quickly enough?
--  Benchmark: Triage 1 ≤ 0 min, T2 ≤ 10, T3 ≤ 30, T4 ≤ 60, T5 ≤ 120
-- ============================================================
SELECT
    triage_category,
    CASE triage_category
        WHEN 1 THEN 'Immediate (Critical)'
        WHEN 2 THEN 'Emergency'
        WHEN 3 THEN 'Urgent'
        WHEN 4 THEN 'Semi-Urgent'
        WHEN 5 THEN 'Non-Urgent'
    END                                         AS triage_label,
    COUNT(*)                                    AS patient_count,
    ROUND(AVG(wait_time_mins), 1)              AS avg_wait_mins,
    MIN(wait_time_mins)                         AS min_wait,
    MAX(wait_time_mins)                         AS max_wait,
    CASE triage_category
        WHEN 1 THEN 0
        WHEN 2 THEN 10
        WHEN 3 THEN 30
        WHEN 4 THEN 60
        WHEN 5 THEN 120
    END                                         AS benchmark_mins,
    ROUND(AVG(wait_time_mins), 1) - CASE triage_category
        WHEN 1 THEN 0  WHEN 2 THEN 10
        WHEN 3 THEN 30 WHEN 4 THEN 60  WHEN 5 THEN 120
    END                                         AS variance_from_benchmark
FROM ed_admissions
GROUP BY triage_category
ORDER BY triage_category;


-- ============================================================
--  QUERY 3 — Patient Volume by Hour of Day
--  Business Question: When are our peak demand periods?
--  Use for staffing rostering and capacity planning
-- ============================================================
SELECT
    hour_of_day,
    LPAD(CONCAT(hour_of_day, ':00'), 5, '0')   AS hour_label,
    COUNT(*)                                    AS patient_count,
    ROUND(COUNT(*) * 100.0 /
          (SELECT COUNT(*) FROM ed_admissions), 1)  AS pct_of_total,
    ROUND(AVG(wait_time_mins), 1)              AS avg_wait_mins,
    CASE
        WHEN hour_of_day BETWEEN 8  AND 11 THEN 'Morning Peak'
        WHEN hour_of_day BETWEEN 14 AND 19 THEN 'Afternoon Peak'
        WHEN hour_of_day BETWEEN 22 AND 23
          OR hour_of_day BETWEEN 0  AND 5  THEN 'Night'
        ELSE 'Off-Peak'
    END                                         AS demand_period
FROM ed_admissions
GROUP BY hour_of_day
ORDER BY hour_of_day;


-- ============================================================
--  QUERY 4 — Performance by Staff Shift
--  Business Question: Does shift type affect patient wait times?
-- ============================================================
SELECT
    staff_shift,
    COUNT(*)                                    AS patients_seen,
    ROUND(AVG(wait_time_mins), 1)              AS avg_wait_mins,
    ROUND(AVG(length_of_stay_hrs), 1)          AS avg_los_hours,
    SUM(CASE WHEN discharge_status = 'Left Without Being Seen'
             THEN 1 ELSE 0 END)                AS lwbs_count,
    ROUND(
        SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                           AS readmission_rate_pct
FROM ed_admissions
GROUP BY staff_shift
ORDER BY avg_wait_mins DESC;


-- ============================================================
--  QUERY 5 — Readmission Rate by Age Group
--  Business Question: Which patient cohort has the highest readmission risk?
-- ============================================================
SELECT
    age_group,
    COUNT(*)                                    AS total_patients,
    SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END)
                                                AS readmitted_count,
    ROUND(
        SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                           AS readmission_rate_pct,
    ROUND(AVG(length_of_stay_hrs), 1)          AS avg_los_hours,
    ROUND(AVG(age), 0)                          AS avg_age_in_group
FROM ed_admissions
GROUP BY age_group
ORDER BY FIELD(age_group, '0-17','18-34','35-49','50-64','65+');  -- MySQL
-- ORDER BY age_group;  -- use for PostgreSQL


-- ============================================================
--  QUERY 6 — Top Chief Complaints by Volume and Severity
--  Business Question: What conditions are driving our workload?
-- ============================================================
SELECT
    chief_complaint,
    COUNT(*)                                    AS total_cases,
    ROUND(AVG(triage_category), 2)             AS avg_triage_severity,
    ROUND(AVG(wait_time_mins), 1)              AS avg_wait_mins,
    ROUND(AVG(length_of_stay_hrs), 1)          AS avg_los_hours,
    SUM(CASE WHEN discharge_status = 'Admitted to Ward'
             THEN 1 ELSE 0 END)                AS admitted_count,
    ROUND(
        SUM(CASE WHEN discharge_status = 'Admitted to Ward'
                 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                           AS admission_rate_pct
FROM ed_admissions
GROUP BY chief_complaint
ORDER BY total_cases DESC
LIMIT 10;


-- ============================================================
--  QUERY 7 — Monthly Trend Analysis
--  Business Question: Is patient volume increasing over the year?
-- ============================================================
SELECT
    month_num,
    month,
    COUNT(*)                                    AS patient_count,
    ROUND(AVG(wait_time_mins), 1)              AS avg_wait_mins,
    ROUND(AVG(length_of_stay_hrs), 1)          AS avg_los_hours,
    SUM(bed_occupied)                           AS beds_occupied,
    -- Month-over-Month change (requires LAG window function)
    COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY month_num)
                                                AS mom_volume_change
FROM ed_admissions
GROUP BY month_num, month
ORDER BY month_num;


-- ============================================================
--  QUERY 8 — Department Efficiency Comparison
--  Business Question: Which departments are under most strain?
-- ============================================================
SELECT
    department,
    COUNT(*)                                    AS total_patients,
    ROUND(AVG(wait_time_mins), 1)              AS avg_wait_mins,
    ROUND(AVG(length_of_stay_hrs), 1)          AS avg_los_hours,
    SUM(bed_occupied)                           AS total_beds_used,
    ROUND(SUM(bed_occupied) * 100.0 / COUNT(*), 1)
                                                AS bed_utilisation_pct,
    ROUND(
        SUM(CASE WHEN readmitted_30_days = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                           AS readmission_rate_pct
FROM ed_admissions
GROUP BY department
ORDER BY avg_wait_mins DESC;


-- ============================================================
--  QUERY 9 — "Left Without Being Seen" Risk Profile
--  Business Question: Who are we losing before treatment?
--  Operational Risk: LWBS patients may deteriorate at home.
-- ============================================================
SELECT
    triage_category,
    age_group,
    staff_shift,
    COUNT(*)                                    AS lwbs_count,
    ROUND(AVG(wait_time_mins), 1)              AS avg_wait_before_leaving
FROM ed_admissions
WHERE discharge_status = 'Left Without Being Seen'
GROUP BY triage_category, age_group, staff_shift
ORDER BY lwbs_count DESC
LIMIT 15;


-- ============================================================
--  QUERY 10 — Discharge Status Breakdown by Triage
--  Business Question: Are we converting the right patients to inpatient?
-- ============================================================
SELECT
    triage_category,
    discharge_status,
    COUNT(*)                                    AS patient_count,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (PARTITION BY triage_category), 1)
                                                AS pct_within_triage
FROM ed_admissions
GROUP BY triage_category, discharge_status
ORDER BY triage_category, patient_count DESC;


-- ============================================================
--  BONUS — High-Risk Patient Flag View
--  Identify patients flagged for follow-up care coordination
-- ============================================================
CREATE OR REPLACE VIEW vw_high_risk_patients AS
SELECT
    patient_id,
    admission_date,
    age,
    age_group,
    triage_category,
    chief_complaint,
    department,
    wait_time_mins,
    length_of_stay_hrs,
    discharge_status,
    readmitted_30_days,
    CASE
        WHEN triage_category IN (1,2) AND readmitted_30_days = 'Yes'  THEN 'CRITICAL'
        WHEN age >= 65               AND readmitted_30_days = 'Yes'   THEN 'HIGH'
        WHEN triage_category = 3     AND readmitted_30_days = 'Yes'   THEN 'MEDIUM'
        WHEN discharge_status = 'Left Without Being Seen'             THEN 'MONITOR'
        ELSE 'STANDARD'
    END AS risk_flag
FROM ed_admissions
WHERE readmitted_30_days = 'Yes'
   OR discharge_status IN ('Left Without Being Seen', 'Transferred')
ORDER BY
    FIELD(risk_flag, 'CRITICAL','HIGH','MEDIUM','MONITOR','STANDARD'),
    admission_date;
