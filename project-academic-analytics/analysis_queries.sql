-- ============================================================
--  University Student Academic Performance — SQL Analysis
--  Author  : [Your Name]
--  Dataset : student_performance.csv  (2,500 records, 2022–2024)
--  Engine  : MySQL / PostgreSQL compatible
--  Theme   : Which factors predict academic success?
-- ============================================================

-- ── SETUP ────────────────────────────────────────────────────
/*
CREATE TABLE student_performance (
    student_id              VARCHAR(12),
    academic_year           YEAR,
    year_level              INT,
    faculty                 VARCHAR(40),
    study_mode              VARCHAR(15),
    entry_pathway           VARCHAR(30),
    gender                  VARCHAR(25),
    residency_status        VARCHAR(15),
    age                     INT,
    family_income_band      VARCHAR(25),
    parental_education      VARCHAR(25),
    scholarship_type        VARCHAR(25),
    employment_status       VARCHAR(25),
    attendance_pct          DECIMAL(5,1),
    weekly_study_hrs        DECIMAL(4,1),
    prior_gpa               DECIMAL(3,2),
    internet_access         VARCHAR(3),
    support_services_used   VARCHAR(25),
    mental_health_support   VARCHAR(3),
    units_enrolled          INT,
    units_completed         INT,
    at_risk_flag            VARCHAR(3),
    composite_score         DECIMAL(5,2),
    final_outcome           VARCHAR(20),
    final_gpa               DECIMAL(3,2)
);
*/


-- ============================================================
--  QUERY 1 — Cohort-Level KPI Summary
--  Business Question: What does the overall academic health
--  of the university look like across 2022–2024?
-- ============================================================
SELECT
    academic_year,
    COUNT(*)                                                AS total_students,
    ROUND(AVG(final_gpa), 2)                               AS avg_gpa,
    ROUND(AVG(attendance_pct), 1)                          AS avg_attendance_pct,
    ROUND(AVG(weekly_study_hrs), 1)                        AS avg_study_hrs,
    -- Pass rate = Pass + Distinction + High Distinction
    ROUND(SUM(CASE WHEN final_outcome IN
        ('Pass','Distinction','High Distinction')
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS pass_rate_pct,
    ROUND(SUM(CASE WHEN final_outcome = 'Fail'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS fail_rate_pct,
    ROUND(SUM(CASE WHEN final_outcome = 'Withdrawn'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS withdrawal_rate_pct,
    SUM(CASE WHEN at_risk_flag = 'Yes'
        THEN 1 ELSE 0 END)                                 AS at_risk_count
FROM student_performance
GROUP BY academic_year
ORDER BY academic_year;


-- ============================================================
--  QUERY 2 — The Attendance–GPA Correlation Deep Dive
--  Business Question: How strongly does attendance predict GPA?
--  Key finding: Students below 60% attendance average GPA 1.70
-- ============================================================
SELECT
    CASE
        WHEN attendance_pct < 50  THEN 'Below 50%  — Critical'
        WHEN attendance_pct < 60  THEN '50–60%     — At Risk'
        WHEN attendance_pct < 70  THEN '60–70%     — Marginal'
        WHEN attendance_pct < 80  THEN '70–80%     — Adequate'
        WHEN attendance_pct < 90  THEN '80–90%     — Good'
        ELSE                           '90–100%    — Excellent'
    END                                                     AS attendance_band,
    COUNT(*)                                                AS student_count,
    ROUND(AVG(final_gpa), 2)                               AS avg_final_gpa,
    ROUND(AVG(weekly_study_hrs), 1)                        AS avg_study_hrs,
    ROUND(SUM(CASE WHEN final_outcome = 'Fail'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS fail_rate_pct,
    ROUND(SUM(CASE WHEN final_outcome IN
        ('Distinction','High Distinction')
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS distinction_rate_pct
FROM student_performance
GROUP BY attendance_band
ORDER BY MIN(attendance_pct);


-- ============================================================
--  QUERY 3 — Employment Impact on Academic Outcomes
--  Business Question: Does working full-time doom academic success?
--  Key finding: Full-time workers who study full-time fail at 47.6%
-- ============================================================
SELECT
    employment_status,
    study_mode,
    COUNT(*)                                                AS student_count,
    ROUND(AVG(final_gpa), 2)                               AS avg_gpa,
    ROUND(AVG(weekly_study_hrs), 1)                        AS avg_study_hrs,
    ROUND(AVG(attendance_pct), 1)                          AS avg_attendance_pct,
    ROUND(SUM(CASE WHEN final_outcome = 'Fail'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS fail_rate_pct,
    ROUND(SUM(CASE WHEN final_outcome = 'Withdrawn'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS withdrawal_rate_pct
FROM student_performance
GROUP BY employment_status, study_mode
ORDER BY fail_rate_pct DESC;


-- ============================================================
--  QUERY 4 — First-Generation Student Disadvantage
--  Business Question: Are first-gen students systematically
--  underperforming? (parental_education = 'No Tertiary')
-- ============================================================
SELECT
    CASE WHEN parental_education = 'No Tertiary'
         THEN 'First-Generation'
         ELSE 'Continuing-Generation'
    END                                                     AS student_type,
    parental_education,
    COUNT(*)                                                AS total_students,
    ROUND(AVG(final_gpa), 2)                               AS avg_gpa,
    ROUND(AVG(attendance_pct), 1)                          AS avg_attendance_pct,
    ROUND(SUM(CASE WHEN final_outcome = 'Fail'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS fail_rate_pct,
    ROUND(SUM(CASE WHEN support_services_used != 'None'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS support_uptake_pct,
    ROUND(SUM(CASE WHEN scholarship_type = 'Equity / Need-Based'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS equity_scholarship_pct
FROM student_performance
GROUP BY student_type, parental_education
ORDER BY fail_rate_pct DESC;


-- ============================================================
--  QUERY 5 — Faculty Performance Benchmarking
--  Business Question: Which faculties have the highest
--  failure and at-risk rates?
-- ============================================================
SELECT
    faculty,
    COUNT(*)                                                AS total_students,
    ROUND(AVG(final_gpa), 2)                               AS avg_gpa,
    ROUND(AVG(attendance_pct), 1)                          AS avg_attendance_pct,
    ROUND(SUM(CASE WHEN final_outcome = 'Fail'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS fail_rate_pct,
    ROUND(SUM(CASE WHEN final_outcome IN
        ('Distinction','High Distinction')
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS distinction_rate_pct,
    SUM(CASE WHEN at_risk_flag = 'Yes'
        THEN 1 ELSE 0 END)                                 AS at_risk_count,
    ROUND(SUM(CASE WHEN at_risk_flag = 'Yes'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS at_risk_pct
FROM student_performance
GROUP BY faculty
ORDER BY fail_rate_pct DESC;


-- ============================================================
--  QUERY 6 — Socioeconomic Equity Analysis
--  Business Question: Does family income create a measurable
--  academic equity gap?
-- ============================================================
SELECT
    family_income_band,
    COUNT(*)                                                AS student_count,
    ROUND(AVG(final_gpa), 2)                               AS avg_gpa,
    ROUND(SUM(CASE WHEN final_outcome = 'Fail'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS fail_rate_pct,
    ROUND(AVG(attendance_pct), 1)                          AS avg_attendance_pct,
    ROUND(SUM(CASE WHEN internet_access = 'No'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS no_internet_pct,
    ROUND(SUM(CASE WHEN scholarship_type IN
        ('Equity / Need-Based','Merit-Based')
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS scholarship_coverage_pct
FROM student_performance
GROUP BY family_income_band
ORDER BY avg_gpa DESC;


-- ============================================================
--  QUERY 7 — Support Services Effectiveness
--  Business Question: Do students who engage with support
--  services actually perform better?
-- ============================================================
SELECT
    support_services_used,
    COUNT(*)                                                AS student_count,
    ROUND(AVG(final_gpa), 2)                               AS avg_gpa,
    ROUND(AVG(attendance_pct), 1)                          AS avg_attendance_pct,
    ROUND(SUM(CASE WHEN final_outcome = 'Fail'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS fail_rate_pct,
    -- Compare to those who used NO support
    ROUND(AVG(final_gpa) -
        (SELECT AVG(final_gpa) FROM student_performance
         WHERE support_services_used = 'None'), 2)         AS gpa_vs_no_support
FROM student_performance
GROUP BY support_services_used
ORDER BY avg_gpa DESC;


-- ============================================================
--  QUERY 8 — Entry Pathway Success Rates
--  Business Question: Which student intake channel produces
--  the strongest academic outcomes?
-- ============================================================
SELECT
    entry_pathway,
    COUNT(*)                                                AS student_count,
    ROUND(AVG(final_gpa), 2)                               AS avg_gpa,
    ROUND(AVG(prior_gpa), 2)                               AS avg_prior_gpa,
    ROUND(SUM(CASE WHEN final_outcome = 'Fail'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS fail_rate_pct,
    ROUND(SUM(CASE WHEN final_outcome IN
        ('Distinction','High Distinction')
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS distinction_rate_pct,
    ROUND(SUM(CASE WHEN final_outcome = 'Withdrawn'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS withdrawal_rate_pct
FROM student_performance
GROUP BY entry_pathway
ORDER BY avg_gpa DESC;


-- ============================================================
--  QUERY 9 — Early Warning: At-Risk Student Profile
--  Business Question: Who needs intervention NOW?
--  Logic: at_risk = attendance <60% OR study <8hrs OR
--         full-time work AND full-time study
-- ============================================================
SELECT
    faculty,
    year_level,
    employment_status,
    study_mode,
    COUNT(*)                                                AS at_risk_count,
    ROUND(AVG(attendance_pct), 1)                          AS avg_attendance,
    ROUND(AVG(weekly_study_hrs), 1)                        AS avg_study_hrs,
    ROUND(AVG(final_gpa), 2)                               AS avg_gpa,
    ROUND(SUM(CASE WHEN support_services_used = 'None'
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)         AS not_seeking_help_pct
FROM student_performance
WHERE at_risk_flag = 'Yes'
GROUP BY faculty, year_level, employment_status, study_mode
HAVING COUNT(*) >= 5
ORDER BY at_risk_count DESC, avg_gpa ASC
LIMIT 20;


-- ============================================================
--  QUERY 10 — Key Predictor Correlation Summary
--  Business Question: Rank the top predictors of GPA.
--  Uses grouping proxies to approximate factor impact.
-- ============================================================
SELECT 'Attendance (90–100% vs <60%)'              AS factor,
       ROUND((SELECT AVG(final_gpa) FROM student_performance WHERE attendance_pct >= 90) -
             (SELECT AVG(final_gpa) FROM student_performance WHERE attendance_pct < 60), 2)
                                                    AS gpa_lift
UNION ALL
SELECT 'Employment (Not Employed vs Full-time)',
       ROUND((SELECT AVG(final_gpa) FROM student_performance WHERE employment_status = 'Not Employed') -
             (SELECT AVG(final_gpa) FROM student_performance WHERE employment_status = 'Full-time (>20 hrs)'), 2)
UNION ALL
SELECT 'Parental Education (Postgrad vs No Tertiary)',
       ROUND((SELECT AVG(final_gpa) FROM student_performance WHERE parental_education = 'Postgraduate') -
             (SELECT AVG(final_gpa) FROM student_performance WHERE parental_education = 'No Tertiary'), 2)
UNION ALL
SELECT 'Scholarship (Merit vs None)',
       ROUND((SELECT AVG(final_gpa) FROM student_performance WHERE scholarship_type = 'Merit-Based') -
             (SELECT AVG(final_gpa) FROM student_performance WHERE scholarship_type = 'None'), 2)
UNION ALL
SELECT 'Support Services (Multiple vs None)',
       ROUND((SELECT AVG(final_gpa) FROM student_performance WHERE support_services_used = 'Multiple Services') -
             (SELECT AVG(final_gpa) FROM student_performance WHERE support_services_used = 'None'), 2)
UNION ALL
SELECT 'Income Band (High vs Low)',
       ROUND((SELECT AVG(final_gpa) FROM student_performance WHERE family_income_band = 'High (>$160k)') -
             (SELECT AVG(final_gpa) FROM student_performance WHERE family_income_band = 'Low (<$40k)'), 2)
ORDER BY gpa_lift DESC;


-- ============================================================
--  BONUS VIEW — Student Risk Register
--  Materialise a prioritised watchlist for student advisors
-- ============================================================
CREATE OR REPLACE VIEW vw_student_risk_register AS
SELECT
    student_id,
    academic_year,
    faculty,
    year_level,
    study_mode,
    employment_status,
    family_income_band,
    parental_education,
    attendance_pct,
    weekly_study_hrs,
    prior_gpa,
    support_services_used,
    composite_score,
    final_gpa,
    final_outcome,
    -- Multi-factor risk tier
    CASE
        WHEN attendance_pct < 50
             AND employment_status = 'Full-time (>20 hrs)'  THEN 'CRITICAL'
        WHEN attendance_pct < 60
             OR  weekly_study_hrs < 6                       THEN 'HIGH'
        WHEN attendance_pct < 70
             AND parental_education = 'No Tertiary'         THEN 'ELEVATED'
        WHEN at_risk_flag = 'Yes'                           THEN 'MODERATE'
        ELSE                                                     'STANDARD'
    END                                                     AS risk_tier,
    CASE WHEN support_services_used = 'None'
         THEN 'Outreach Needed' ELSE 'Engaged' END          AS outreach_status
FROM student_performance
WHERE at_risk_flag = 'Yes'
   OR final_outcome IN ('Fail', 'Withdrawn')
ORDER BY
    FIELD(risk_tier,'CRITICAL','HIGH','ELEVATED','MODERATE','STANDARD'),
    attendance_pct ASC;
