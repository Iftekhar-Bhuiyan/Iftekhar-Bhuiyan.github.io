"""
Hospital Emergency Department Dataset Generator
================================================
Run this script to generate a realistic 2,000-row CSV dataset
for the ED Performance Analysis case study.

Usage:
    python generate_dataset.py

Output:
    hospital_ed_data.csv  (in the same folder)

Requirements:
    pip install pandas numpy faker
"""

import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

# ── Reproducibility ─────────────────────────────────────────────────────────
SEED = 42
np.random.seed(SEED)
random.seed(SEED)

# ── Config ───────────────────────────────────────────────────────────────────
N_PATIENTS     = 2000
START_DATE     = datetime(2024, 1, 1)
END_DATE       = datetime(2024, 12, 31)
OUTPUT_FILE    = "hospital_ed_data.csv"

DEPARTMENTS    = ["Emergency", "General Medicine", "Surgical", "Pediatrics", "ICU"]
TRIAGE_CATS    = [1, 2, 3, 4, 5]          # 1 = most urgent, 5 = least urgent
TRIAGE_WEIGHTS = [0.05, 0.15, 0.35, 0.30, 0.15]
GENDERS        = ["Male", "Female", "Non-binary / Other"]
GENDER_WEIGHTS = [0.48, 0.49, 0.03]
DISCHARGE_STATUSES = [
    "Discharged Home", "Admitted to Ward", "Transferred",
    "Left Without Being Seen", "Deceased"
]
DISCHARGE_WEIGHTS  = [0.58, 0.28, 0.07, 0.05, 0.02]
SHIFTS         = ["Morning (06:00-14:00)", "Afternoon (14:00-22:00)", "Night (22:00-06:00)"]
CHIEF_COMPLAINTS = [
    "Chest Pain", "Shortness of Breath", "Abdominal Pain", "Head Injury",
    "Fracture / Dislocation", "Fever / Infection", "Stroke Symptoms",
    "Allergic Reaction", "Mental Health Crisis", "Overdose / Poisoning",
    "Laceration / Wound", "Urinary Tract Infection", "Back Pain",
    "Dizziness / Syncope", "Cardiac Arrhythmia"
]

# ── Helper: Random Timestamp ─────────────────────────────────────────────────
def random_timestamp(start, end):
    delta = end - start
    random_seconds = random.randint(0, int(delta.total_seconds()))
    return start + timedelta(seconds=random_seconds)

# ── Helper: Shift from Hour ──────────────────────────────────────────────────
def get_shift(hour):
    if 6 <= hour < 14:
        return "Morning (06:00-14:00)"
    elif 14 <= hour < 22:
        return "Afternoon (14:00-22:00)"
    else:
        return "Night (22:00-06:00)"

# ── Helper: Wait Time (minutes) — varies by triage, shift, and weekday ──────
def wait_time(triage, hour, weekday, age):
    base = {1: 8, 2: 18, 3: 42, 4: 62, 5: 85}[triage]
    # Peak hours: 8-11am and 4-7pm add congestion
    peak_adj = 15 if (8 <= hour <= 11) or (16 <= hour <= 19) else 0
    # Night shift is slower
    night_adj = 12 if (hour >= 22 or hour < 6) else 0
    # Weekends slightly busier
    weekend_adj = 8 if weekday >= 5 else 0
    # Elderly patients take longer to process
    age_adj = 6 if age >= 65 else 0
    raw = base + peak_adj + night_adj + weekend_adj + age_adj
    noise = np.random.normal(0, raw * 0.18)
    return max(3, round(raw + noise))

# ── Helper: Length of Stay (hours) ──────────────────────────────────────────
def length_of_stay(triage, discharge_status, age):
    base = {1: 18, 2: 10, 3: 5, 4: 3, 5: 2}[triage]
    if discharge_status == "Admitted to Ward":
        base *= 2.8
    elif discharge_status == "Transferred":
        base *= 1.6
    elif discharge_status == "Left Without Being Seen":
        base = round(base * 0.3)
    age_factor = 1.25 if age >= 65 else (1.1 if age >= 50 else 1.0)
    raw = base * age_factor
    noise = np.random.normal(0, raw * 0.22)
    return max(0.5, round(raw + noise, 1))

# ── Helper: Department from Triage / Complaint ───────────────────────────────
def assign_department(triage, complaint, age):
    if age < 16:
        return "Pediatrics"
    if triage == 1:
        return random.choice(["ICU", "Emergency"])
    if complaint in ["Cardiac Arrhythmia", "Chest Pain", "Stroke Symptoms"]:
        return random.choice(["Emergency", "ICU"])
    if complaint in ["Fracture / Dislocation", "Laceration / Wound"]:
        return random.choice(["Surgical", "Emergency"])
    return random.choices(
        ["Emergency", "General Medicine", "Surgical", "ICU"],
        weights=[0.50, 0.30, 0.15, 0.05]
    )[0]

# ── Helper: Readmission (30-day) ─────────────────────────────────────────────
def readmitted(triage, age, discharge_status):
    if discharge_status in ["Deceased", "Left Without Being Seen"]:
        return "No"
    base_prob = {1: 0.22, 2: 0.14, 3: 0.08, 4: 0.04, 5: 0.02}[triage]
    age_adj = 0.12 if age >= 65 else (0.04 if age >= 50 else 0.0)
    prob = min(0.45, base_prob + age_adj)
    return "Yes" if random.random() < prob else "No"

# ── Build Dataset ─────────────────────────────────────────────────────────────
records = []
for i in range(1, N_PATIENTS + 1):

    admission_dt   = random_timestamp(START_DATE, END_DATE)
    triage         = random.choices(TRIAGE_CATS, weights=TRIAGE_WEIGHTS)[0]
    age            = int(np.random.choice(
        range(1, 100),
        p=np.array([
            *([0.003] * 15),   # 1-15 (paeds)
            *([0.008] * 30),   # 16-45
            *([0.012] * 25),   # 46-70
            *([0.016] * 29)    # 71-99 (elderly skew)
        ]) / sum([
            *([0.003] * 15), *([0.008] * 30),
            *([0.012] * 25), *([0.016] * 29)
        ])
    ))
    gender         = random.choices(GENDERS, weights=GENDER_WEIGHTS)[0]
    complaint      = random.choice(CHIEF_COMPLAINTS)
    department     = assign_department(triage, complaint, age)
    hour           = admission_dt.hour
    weekday        = admission_dt.weekday()   # 0=Mon, 6=Sun
    shift          = get_shift(hour)
    wt             = wait_time(triage, hour, weekday, age)
    discharge_st   = random.choices(DISCHARGE_STATUSES, weights=DISCHARGE_WEIGHTS)[0]
    los            = length_of_stay(triage, discharge_st, age)
    readmit        = readmitted(triage, age, discharge_st)
    bed_occupied   = 1 if discharge_st in ["Admitted to Ward", "Transferred"] else 0

    records.append({
        "patient_id":           f"PT-{i:05d}",
        "admission_date":       admission_dt.strftime("%Y-%m-%d"),
        "admission_time":       admission_dt.strftime("%H:%M"),
        "day_of_week":          admission_dt.strftime("%A"),
        "hour_of_day":          hour,
        "month":                admission_dt.strftime("%B"),
        "month_num":            admission_dt.month,
        "staff_shift":          shift,
        "age":                  age,
        "age_group":            (
            "0-17"  if age < 18 else
            "18-34" if age < 35 else
            "35-49" if age < 50 else
            "50-64" if age < 65 else
            "65+"
        ),
        "gender":               gender,
        "triage_category":      triage,
        "chief_complaint":      complaint,
        "department":           department,
        "wait_time_mins":       wt,
        "length_of_stay_hrs":   los,
        "discharge_status":     discharge_st,
        "bed_occupied":         bed_occupied,
        "readmitted_30_days":   readmit,
    })

df = pd.DataFrame(records)

# ── Summary Stats (printed for reference) ────────────────────────────────────
print("=" * 55)
print("  DATASET GENERATED SUCCESSFULLY")
print("=" * 55)
print(f"  Total records  : {len(df):,}")
print(f"  Date range     : {df['admission_date'].min()}  →  {df['admission_date'].max()}")
print(f"  Avg wait time  : {df['wait_time_mins'].mean():.1f} mins")
print(f"  Avg LOS        : {df['length_of_stay_hrs'].mean():.1f} hours")
print(f"  Readmission %  : {(df['readmitted_30_days']=='Yes').mean()*100:.1f}%")
print(f"  Triage 1-2 %   : {(df['triage_category']<=2).mean()*100:.1f}%")
print("=" * 55)
print(f"\n  Saved to: {OUTPUT_FILE}\n")

df.to_csv(OUTPUT_FILE, index=False)
