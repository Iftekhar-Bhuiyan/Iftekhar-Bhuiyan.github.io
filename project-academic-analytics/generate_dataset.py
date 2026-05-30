"""
University Student Academic Performance Dataset Generator
==========================================================
Generates a realistic 2,500-row dataset across 3 academic years
covering demographics, behaviour, socioeconomic background,
and final academic outcomes.

Usage:
    python generate_dataset.py

Output:
    student_performance.csv

Requirements:
    pip install pandas numpy
"""

import pandas as pd
import numpy as np
import random

# ── Reproducibility ───────────────────────────────────────────
SEED = 2024
np.random.seed(SEED)
random.seed(SEED)

N                = 2500
OUTPUT_FILE      = "student_performance.csv"

# ── Lookup tables ─────────────────────────────────────────────
FACULTIES = ["Engineering", "Business", "Health Sciences",
             "Arts & Humanities", "Information Technology", "Education"]
FAC_W     = [0.20, 0.22, 0.18, 0.14, 0.16, 0.10]

YEAR_LEVELS      = [1, 2, 3, 4]
YEAR_W           = [0.32, 0.28, 0.24, 0.16]

GENDERS          = ["Male", "Female", "Non-binary / Other"]
GENDER_W         = [0.47, 0.50, 0.03]

RESIDENCY        = ["Domestic", "International"]
RESIDENCY_W      = [0.72, 0.28]

ENTRY_PATHWAYS   = ["High School (ATAR)", "TAFE / Diploma",
                    "Mature Age Entry", "Transfer / Credit", "International Pathway"]
ENTRY_W          = [0.48, 0.18, 0.14, 0.12, 0.08]

INCOME_BANDS     = ["Low (<$40k)", "Lower-Mid ($40–70k)",
                    "Mid ($70–110k)", "Upper-Mid ($110–160k)", "High (>$160k)"]
INCOME_W         = [0.18, 0.24, 0.28, 0.18, 0.12]

PARENTAL_EDU     = ["No Tertiary", "TAFE / Certificate", "Bachelor", "Postgraduate"]
PARENT_W         = [0.22, 0.20, 0.38, 0.20]

MODES            = ["Full-time", "Part-time"]
MODE_W           = [0.68, 0.32]

EMPLOYMENT       = ["Not Employed", "Part-time (≤20 hrs)", "Full-time (>20 hrs)"]
EMPLOY_W         = [0.38, 0.44, 0.18]

OUTCOMES         = ["Pass", "Fail", "Distinction", "High Distinction", "Withdrawn"]
# Outcome weights derived from factors — see function below

ACADEMIC_YEAR    = ["2022", "2023", "2024"]
ACAD_W           = [0.30, 0.35, 0.35]

SUPPORT_USED     = ["None", "Peer Tutoring", "Academic Advisor",
                    "Counselling", "Multiple Services"]
SUPPORT_W        = [0.42, 0.18, 0.22, 0.08, 0.10]

SCHOLARSHIPS     = ["None", "Merit-Based", "Equity / Need-Based", "External"]
SCHOLAR_W        = [0.55, 0.20, 0.15, 0.10]

# ── Score builder: composite academic risk score ──────────────
def build_score(attendance_pct, study_hrs_wk, prior_gpa,
                employed, income_band, parental_edu,
                mode, scholarship, yr_level, support):
    """
    Returns a float 0–100 representing predicted academic performance.
    Higher = stronger outcome.
    """
    s = 0.0

    # Attendance (strongest single predictor)
    s += attendance_pct * 0.35        # 0–35 pts

    # Study hours (diminishing returns above 20 hrs)
    s += min(study_hrs_wk, 25) * 0.7  # 0–17.5 pts

    # Prior academic record
    s += prior_gpa * 4.5              # 0–18 pts (prior_gpa 0–4.0)

    # Employment penalty
    s += {"Not Employed": 5,
          "Part-time (≤20 hrs)": 2,
          "Full-time (>20 hrs)": -4}[employed]

    # Socioeconomic advantage
    s += {"Low (<$40k)": -3,
          "Lower-Mid ($40–70k)": -1,
          "Mid ($70–110k)": 0,
          "Upper-Mid ($110–160k)": 1,
          "High (>$160k)": 2}[income_band]

    # Parental education (first-gen penalty)
    s += {"No Tertiary": -3,
          "TAFE / Certificate": -1,
          "Bachelor": 1,
          "Postgraduate": 2}[parental_edu]

    # Full-time students slightly higher
    s += 2 if mode == "Full-time" else 0

    # Scholarship signal
    s += {"None": 0, "Merit-Based": 3,
          "Equity / Need-Based": 1, "External": 2}[scholarship]

    # Support services (indicates proactive behaviour)
    s += {"None": 0, "Peer Tutoring": 2,
          "Academic Advisor": 3, "Counselling": 1,
          "Multiple Services": 4}[support]

    # Year level: more experienced students slightly better
    s += yr_level * 0.5

    # Add controlled noise
    noise = np.random.normal(0, 6)
    s += noise

    return round(np.clip(s, 0, 100), 2)

# ── Map score to outcome ──────────────────────────────────────
def score_to_outcome(score, at_risk_flag):
    if score >= 82:
        return random.choices(
            ["High Distinction", "Distinction"],
            weights=[0.55, 0.45])[0]
    elif score >= 68:
        return random.choices(
            ["Distinction", "Pass"],
            weights=[0.45, 0.55])[0]
    elif score >= 52:
        return "Pass"
    elif score >= 38:
        return random.choices(
            ["Pass", "Fail"],
            weights=[0.35, 0.65])[0]
    else:
        return random.choices(
            ["Fail", "Withdrawn"],
            weights=[0.60, 0.40])[0]

# ── GPA from outcome ──────────────────────────────────────────
def outcome_to_gpa(outcome):
    mapping = {
        "High Distinction": round(np.random.uniform(3.7, 4.0), 2),
        "Distinction":      round(np.random.uniform(3.0, 3.69), 2),
        "Pass":             round(np.random.uniform(2.0, 2.99), 2),
        "Fail":             round(np.random.uniform(0.5, 1.99), 2),
        "Withdrawn":        0.0,
    }
    return mapping[outcome]

# ── Build Records ─────────────────────────────────────────────
records = []
for i in range(1, N + 1):

    faculty         = random.choices(FACULTIES, weights=FAC_W)[0]
    year_level      = random.choices(YEAR_LEVELS, weights=YEAR_W)[0]
    gender          = random.choices(GENDERS, weights=GENDER_W)[0]
    residency       = random.choices(RESIDENCY, weights=RESIDENCY_W)[0]
    entry_pathway   = random.choices(ENTRY_PATHWAYS, weights=ENTRY_W)[0]
    income_band     = random.choices(INCOME_BANDS, weights=INCOME_W)[0]
    parental_edu    = random.choices(PARENTAL_EDU, weights=PARENT_W)[0]
    mode            = random.choices(MODES, weights=MODE_W)[0]
    employment      = random.choices(EMPLOYMENT, weights=EMPLOY_W)[0]
    academic_year   = random.choices(ACADEMIC_YEAR, weights=ACAD_W)[0]
    support         = random.choices(SUPPORT_USED, weights=SUPPORT_W)[0]
    scholarship     = random.choices(SCHOLARSHIPS, weights=SCHOLAR_W)[0]

    # Attendance: first-gen, full-time workers attend less
    base_attend = 75
    if parental_edu == "No Tertiary":   base_attend -= 5
    if employment == "Full-time (>20 hrs)": base_attend -= 10
    if mode == "Part-time":             base_attend -= 5
    if residency == "International":    base_attend += 4
    attendance = round(np.clip(
        np.random.normal(base_attend, 12), 20, 100), 1)

    # Study hours/week
    base_study = 14
    if employment == "Full-time (>20 hrs)": base_study -= 5
    if mode == "Full-time":             base_study += 3
    if scholarship == "Merit-Based":    base_study += 2
    study_hrs = round(np.clip(
        np.random.normal(base_study, 5), 1, 40), 1)

    # Prior GPA (incoming academic record)
    base_prior = 2.8
    if entry_pathway == "High School (ATAR)": base_prior += 0.3
    if scholarship   == "Merit-Based":        base_prior += 0.4
    if parental_edu  == "Postgraduate":       base_prior += 0.2
    prior_gpa = round(np.clip(
        np.random.normal(base_prior, 0.6), 0, 4.0), 2)

    # Internet / device access
    internet_access = "Yes" if income_band not in ["Low (<$40k)"] \
                                or random.random() > 0.25 else "No"

    # Mental health support flag
    mental_health_support = "Yes" if support in ["Counselling", "Multiple Services"] else "No"

    # At-risk flag (early warning system)
    at_risk = (attendance < 60 or
               study_hrs < 8 or
               employment == "Full-time (>20 hrs)" and mode == "Full-time")

    # Composite score
    score = build_score(attendance, study_hrs, prior_gpa,
                        employment, income_band, parental_edu,
                        mode, scholarship, year_level, support)

    outcome = score_to_outcome(score, at_risk)
    final_gpa = outcome_to_gpa(outcome)

    # Units enrolled / completed
    units_enrolled  = 4 if mode == "Full-time" else 2
    units_completed = (0 if outcome == "Withdrawn"
                       else units_enrolled if outcome != "Fail"
                       else random.randint(0, units_enrolled - 1))

    records.append({
        "student_id":            f"STU-{i:05d}",
        "academic_year":         academic_year,
        "year_level":            year_level,
        "faculty":               faculty,
        "study_mode":            mode,
        "entry_pathway":         entry_pathway,
        "gender":                gender,
        "residency_status":      residency,
        "age":                   int(np.clip(
                                     np.random.normal(
                                         21 + year_level,
                                         4 if entry_pathway == "Mature Age Entry" else 2),
                                     17, 55)),
        "family_income_band":    income_band,
        "parental_education":    parental_edu,
        "scholarship_type":      scholarship,
        "employment_status":     employment,
        "attendance_pct":        attendance,
        "weekly_study_hrs":      study_hrs,
        "prior_gpa":             prior_gpa,
        "internet_access":       internet_access,
        "support_services_used": support,
        "mental_health_support": mental_health_support,
        "units_enrolled":        units_enrolled,
        "units_completed":       units_completed,
        "at_risk_flag":          "Yes" if at_risk else "No",
        "composite_score":       score,
        "final_outcome":         outcome,
        "final_gpa":             final_gpa,
    })

df = pd.DataFrame(records)

# ── Print Summary ─────────────────────────────────────────────
print("=" * 58)
print("  STUDENT PERFORMANCE DATASET — GENERATED")
print("=" * 58)
print(f"  Total students      : {len(df):,}")
print(f"  Academic years      : {', '.join(df.academic_year.unique())}")
print(f"  Avg attendance      : {df.attendance_pct.mean():.1f}%")
print(f"  Avg weekly study    : {df.weekly_study_hrs.mean():.1f} hrs")
print(f"  Avg final GPA       : {df.final_gpa.mean():.2f}")
print(f"  Pass rate           : {(df.final_outcome.isin(['Pass','Distinction','High Distinction'])).mean()*100:.1f}%")
print(f"  Fail rate           : {(df.final_outcome == 'Fail').mean()*100:.1f}%")
print(f"  Withdrawal rate     : {(df.final_outcome == 'Withdrawn').mean()*100:.1f}%")
print(f"  At-risk students    : {(df.at_risk_flag == 'Yes').sum():,} ({(df.at_risk_flag == 'Yes').mean()*100:.1f}%)")
print()
print("=== Outcome Distribution ===")
print(df.final_outcome.value_counts())
print()
print("=== Avg GPA by Faculty ===")
print(df.groupby("faculty").final_gpa.mean().round(2).sort_values(ascending=False))
print()
print("=== Outcome by Employment Status ===")
print(pd.crosstab(df.employment_status, df.final_outcome, normalize="index").round(3)*100)
print()
print("=== Fail Rate by Income Band ===")
fail = df.groupby("family_income_band").apply(
    lambda x: (x.final_outcome=="Fail").mean()*100).round(1)
print(fail)
print("=" * 58)
print(f"\n  Saved → {OUTPUT_FILE}\n")

df.to_csv(OUTPUT_FILE, index=False)
