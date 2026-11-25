# SQL analysis (SQLite)

## Input and scope

The SQL database is built from `data/exports/fulfillment_pulse_test_predictions.csv`, the Notebook 02 held-out test-prediction export. The expected current project sample is **9,117 rows**. This is the source test split, not the full 45,584-row dataset.

## Files

- `schema.sql`: SQLite `delivery_predictions` table schema and indexes.
- `business_analysis.sql`: **20 core query sections** and one optional, not-yet-validated threshold query.
- `../scripts/load_predictions.py`: CSV-to-SQLite loader using only the Python standard library.

## Load data

From the repository root, after placing the Notebook 02 prediction export in `data/exports/`:

```bash
python scripts/load_predictions.py "data/exports/fulfillment_pulse_test_predictions.csv"
```

This creates/replaces `fulfillment_pulse.db` in the repository root. The loader validates the 20 CSV input columns, normalises null tokens, inserts records in batches, creates indexes on traffic, weather and city, and verifies the loaded count. SQLite generates `row_id`; it is not an original order identifier.

The CSV exports and SQLite database are excluded from Git by default. Regenerate them locally by following `docs/reproducibility.md`.

## Core queries

| Query | Analysis |
|---:|---|
| 01 | Record integrity, unique IDs and target range |
| 02 | Missing-value audit across the 21 table columns |
| 03 | Engineered-feature and error-field consistency |
| 04 | Numerical validity checks |
| 05 | Overall delivery and model-performance KPIs |
| 06 | Delivery performance by traffic density |
| 07 | Delivery performance by weather |
| 08 | Traffic × weather combinations; groups require at least 10 records |
| 09 | Haversine distance bands; records with missing distance are excluded |
| 10 | Recorded `multiple_deliveries` categories |
| 11 | Detailed courier-rating distribution |
| 12 | Courier-rating bands |
| 13 | City-category performance |
| 14 | Order-category performance |
| 15 | Vehicle-category performance |
| 16 | Source festival-indicator analysis |
| 17 | Absolute prediction-error bands |
| 18 | Underprediction versus overprediction; 0.001-minute near-exact tolerance |
| 19 | Prediction direction by traffic density |
| 20 | Severe errors (>10 minutes) by weather × traffic; groups require at least 30 records |

### Optional query 21

Query 21 counts orders with actual delivery duration above a project-defined 30-minute threshold. It is **optional and has not been validated against a recorded output**. The threshold is exploratory and is not a published delivery SLA.

## Interpretation rules

- `error_minutes = actual_minutes - predicted_minutes`.
- Positive signed error means underprediction; negative signed error means overprediction.
- MAE is the average of `absolute_error_minutes`.
- The within-five-minute metric uses an absolute-error threshold of 5 minutes; it is not a delivery SLA.
- The severe-error analysis uses absolute error greater than 10 minutes.
- Query 09 uses straight-line Haversine distance, not road-route distance.
- Missing categories are labelled `Unknown` where the query explicitly coalesces them.
- Group differences are descriptive associations, not causal effects.
- Always read sample counts alongside percentages, especially for small or Unknown groups.
