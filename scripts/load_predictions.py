#!/usr/bin/env python3
"""Load the Notebook 02 prediction CSV into a local SQLite database.

Usage:
    python scripts/load_predictions.py path/to/fulfillment_pulse_test_predictions.csv

Creates/replaces: fulfillment_pulse.db in the current working directory.
Requires only Python's standard library.
"""
from __future__ import annotations

import csv
import sqlite3
import sys
from pathlib import Path

EXPECTED_COLUMNS = [
    "Delivery_person_Age",
    "Delivery_person_Ratings",
    "Vehicle_condition",
    "multiple_deliveries",
    "distance_km",
    "distance_missing",
    "order_hour_sin",
    "order_hour_cos",
    "order_dow_sin",
    "order_dow_cos",
    "Weather_conditions",
    "Road_traffic_density",
    "Type_of_order",
    "Type_of_vehicle",
    "Festival",
    "City",
    "actual_minutes",
    "predicted_minutes",
    "error_minutes",
    "absolute_error_minutes",
]

NUMERIC_COLUMNS = {
    "Delivery_person_Age",
    "Delivery_person_Ratings",
    "Vehicle_condition",
    "multiple_deliveries",
    "distance_km",
    "distance_missing",
    "order_hour_sin",
    "order_hour_cos",
    "order_dow_sin",
    "order_dow_cos",
    "actual_minutes",
    "predicted_minutes",
    "error_minutes",
    "absolute_error_minutes",
}

TEXT_NULLS = {"", "nan", "none", "null", "na", "n/a"}

CREATE_TABLE = """
CREATE TABLE delivery_predictions (
    row_id INTEGER PRIMARY KEY AUTOINCREMENT,
    Delivery_person_Age REAL,
    Delivery_person_Ratings REAL,
    Vehicle_condition REAL,
    multiple_deliveries REAL,
    distance_km REAL,
    distance_missing REAL,
    order_hour_sin REAL,
    order_hour_cos REAL,
    order_dow_sin REAL,
    order_dow_cos REAL,
    Weather_conditions TEXT,
    Road_traffic_density TEXT,
    Type_of_order TEXT,
    Type_of_vehicle TEXT,
    Festival TEXT,
    City TEXT,
    actual_minutes REAL NOT NULL,
    predicted_minutes REAL NOT NULL,
    error_minutes REAL NOT NULL,
    absolute_error_minutes REAL NOT NULL
)
"""


def parse_value(column: str, raw: str | None):
    if raw is None:
        return None
    value = raw.strip()
    if value.lower() in TEXT_NULLS:
        return None
    if column in NUMERIC_COLUMNS:
        try:
            return float(value)
        except ValueError as exc:
            raise ValueError(f"Invalid numeric value {raw!r} in column {column!r}") from exc
    return value


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python scripts/load_predictions.py path/to/fulfillment_pulse_test_predictions.csv")
        return 2

    csv_path = Path(sys.argv[1]).expanduser().resolve()
    if not csv_path.is_file():
        print(f"CSV file not found: {csv_path}")
        return 2

    db_path = Path.cwd() / "fulfillment_pulse.db"
    placeholders = ",".join("?" for _ in EXPECTED_COLUMNS)
    quoted_columns = ",".join(f'"{c}"' for c in EXPECTED_COLUMNS)
    insert_sql = f"INSERT INTO delivery_predictions ({quoted_columns}) VALUES ({placeholders})"

    count = 0
    try:
        with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            actual_columns = reader.fieldnames or []
            missing = [c for c in EXPECTED_COLUMNS if c not in actual_columns]
            if missing:
                raise ValueError(
                    "The CSV is missing expected columns: " + ", ".join(missing)
                    + "\nConfirm that you selected fulfillment_pulse_test_predictions.csv from Notebook 02."
                )

            with sqlite3.connect(db_path) as conn:
                conn.execute("DROP TABLE IF EXISTS delivery_predictions")
                conn.execute(CREATE_TABLE)
                batch = []
                for line_number, row in enumerate(reader, start=2):
                    try:
                        values = [parse_value(c, row.get(c)) for c in EXPECTED_COLUMNS]
                    except ValueError as exc:
                        raise ValueError(f"CSV row {line_number}: {exc}") from exc
                    batch.append(values)
                    if len(batch) >= 1000:
                        conn.executemany(insert_sql, batch)
                        count += len(batch)
                        batch.clear()
                if batch:
                    conn.executemany(insert_sql, batch)
                    count += len(batch)

                conn.execute("CREATE INDEX IF NOT EXISTS idx_delivery_traffic ON delivery_predictions (Road_traffic_density)")
                conn.execute("CREATE INDEX IF NOT EXISTS idx_delivery_weather ON delivery_predictions (Weather_conditions)")
                conn.execute("CREATE INDEX IF NOT EXISTS idx_delivery_city ON delivery_predictions (City)")
                conn.commit()

                check = conn.execute("SELECT COUNT(*) FROM delivery_predictions").fetchone()[0]
                print(f"Database created: {db_path}")
                print(f"Rows loaded: {check:,}")
                print("Table: delivery_predictions")
                if check != count:
                    raise RuntimeError(f"Row-count verification failed: loaded {check}, expected {count}")

    except (OSError, sqlite3.Error, ValueError, RuntimeError) as exc:
        print(f"Import failed: {exc}")
        return 1

    if count != 9117:
        print(f"Note: expected 9,117 test rows based on the current project run; loaded {count:,}. Check whether the correct test-predictions CSV was selected.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
