# FULFILLMENT PULSE — Business Insights & Findings

**Project:** Food-delivery ETA prediction and operational analysis
**Analysis layer:** SQLite SQL analysis, supported by Python model evaluation and Power BI reporting
**Evaluation sample:** 9,117 held-out test records
**Target:** Actual delivery duration (`actual_minutes`), measured in minutes
**Status:** Findings consolidated from the executed notebooks, SQL outputs and Power BI report

---

## 1. Executive summary

FULFILLMENT PULSE analyses a public food-delivery dataset and evaluates whether delivery duration can be estimated from order and operating-condition information. The work combines data-quality checks, feature engineering, regression-model comparison, held-out test evaluation, SQL business analysis and a two-page Power BI report.

The modelling workflow used 36,467 records for training and kept 9,117 records as a separate test set. HistGradientBoosting was selected using validation MAE, refitted on the full training split, and evaluated on the held-out test set.

### Final test-set model performance

| Metric | Result | Interpretation |
|---|---:|---|
| Selected model | HistGradientBoosting | Lowest validation MAE among the compared models |
| Test MAE | **3.154 minutes** | Mean absolute prediction error |
| Test RMSE | **3.981 minutes** | Error metric that penalises larger residuals more strongly |
| Test R² | **0.820** | The model explains approximately 82.0% of the observed target variance in this test sample |
| Predictions within ±5 minutes | **80.62%** | Share with absolute error less than or equal to five minutes |

The SQL analysis found that delivery times differ across traffic, weather, distance, city category, courier-rating band, recorded multiple-delivery value, vehicle type and the source festival indicator. These are descriptive relationships in this dataset; they do not establish that any one factor causes a delivery delay.

### Main findings at a glance

- Average actual delivery time in the test sample was **26.29 minutes**; the median was **26.0 minutes**.
- Jam traffic had the highest average delivery time among traffic categories (**31.21 minutes**); Low traffic had the lowest (**21.13 minutes**).
- Fog had the highest average delivery time among known weather categories (**29.32 minutes**); Sunny had the lowest (**21.64 minutes**).
- The Fog + Jam combination averaged **37.06 minutes** across 507 orders.
- Average delivery time increased from **22.32 minutes** for 0–5 km Haversine distance to **29.86 minutes** for 10–15 km; the 15+ km group averaged 29.72 minutes.
- **80.62%** of test predictions were within five minutes; **1.56%** had absolute errors greater than ten minutes.
- The Unknown weather + Unknown traffic group had a **21.01%** rate of errors greater than ten minutes (25 of 119 records). This small group should be investigated, not generalised to all orders.

---

## 2. Dataset scope and interpretation

The source is a public third-party Food Delivery dataset mirrored on Hugging Face as `aneesarom/Food-Delivery` and associated with a publicly shared Zomato Delivery Operations dataset on Kaggle. The project has **not independently verified that this is an official Zomato production-data release**. It must therefore be described as a public dataset attributed to Zomato delivery operations, not as proprietary or officially released company data.

The source dataset contains **45,584 records**. The modelling workflow retained its source train/test split:

| Split | Records | Use |
|---|---:|---|
| Training | 36,467 | Model fitting and validation-based selection |
| Held-out test | 9,117 | Final model evaluation and the row-level SQL/Power BI analysis |
| Total | 45,584 | Source dataset size |

**Important scope note:** Unless a section explicitly says otherwise, SQL segment counts and averages in this report describe the **9,117-row held-out test sample**, not all 45,584 source records.

The SQL table `delivery_predictions` contains 21 columns: `row_id`, 16 model input features, and four prediction/evaluation fields (`actual_minutes`, `predicted_minutes`, `error_minutes`, and `absolute_error_minutes`).

### Error sign convention

The project defines:

`error_minutes = actual_minutes - predicted_minutes`

- Positive error: **underprediction** — predicted delivery time was lower than actual time.
- Negative error: **overprediction** — predicted delivery time was higher than actual time.
- `absolute_error_minutes`: magnitude of the prediction error, irrespective of direction.

This convention is used throughout the SQL queries and interpretation below.

---

## 3. Data preparation and quality controls

Notebook 1 was used for source-data inspection and initial quality assessment. Notebook 2 prepared the modelling data, engineered features, compared models and exported held-out predictions. The preparation workflow included:

- Standardising common missing-value placeholders and safely converting numeric fields.
- Treating courier ages outside the project plausibility range of 18–65, ratings outside 1–5, vehicle-condition values outside 0/1/2, and multiple-delivery values outside 0–3 as missing rather than deleting the full record.
- Validating coordinate pairs against broad India screening bounds (latitude 6–38, longitude 68–98).
- Calculating straight-line distance using the Haversine formula. Invalid or unavailable coordinate pairs produce a missing distance and a missingness indicator. Distances above 100 km are treated as unusable for this local-delivery estimate and set to missing.
- Parsing order time to create cyclic hour and weekday features.
- Excluding `Time_Order_picked`, IDs and raw coordinates from the model predictors to reduce post-order information leakage and avoid using raw identifiers/coordinates as predictors.
- Retaining records with missing predictor values and handling them within the modelling pipeline rather than dropping the full row.

### 3.1 Record integrity audit

| Check | SQL result |
|---|---:|
| Total records | 9,117 |
| Unique `row_id` values | 9,117 |
| Duplicate non-null row IDs | 0 |
| Missing row IDs | 0 |
| Missing actual delivery times | 0 |
| Missing predicted delivery times | 0 |
| Minimum actual delivery time | 10 minutes |
| Maximum actual delivery time | 54 minutes |

### 3.2 Missing-value audit

The SQL audit checked all 21 exported columns. Eleven columns had missing values; the remaining ten had none.

| Column | Missing values | Share of 9,117 records |
|---|---:|---:|
| `distance_km` | 811 | 8.90% |
| `order_hour_cos` | 419 | 4.60% |
| `order_hour_sin` | 419 | 4.60% |
| `Delivery_person_Ratings` | 372 | 4.08% |
| `Delivery_person_Age` | 363 | 3.98% |
| `City` | 243 | 2.67% |
| `multiple_deliveries` | 203 | 2.23% |
| `Weather_conditions` | 123 | 1.35% |
| `Road_traffic_density` | 119 | 1.31% |
| `Vehicle_condition` | 108 | 1.18% |
| `Festival` | 36 | 0.39% |

There were **3,216 missing cells across 191,457 cells**, an overall missing-cell rate of approximately **1.68%**. The prediction fields and target (`actual_minutes`, `predicted_minutes`, `error_minutes`, `absolute_error_minutes`) had no missing values. Missing distance and operational-category values were retained and are handled as missing/Unknown in analyses where appropriate.

### 3.3 Engineered-field consistency

| Consistency check | Mismatches |
|---|---:|
| `distance_missing` flag versus `distance_km` null status | 0 |
| Paired `order_hour_sin` / `order_hour_cos` missingness | 0 |
| `error_minutes` versus actual minus predicted | 0 |
| `absolute_error_minutes` versus absolute signed error | 0 |

### 3.4 Numerical validity audit

All seven executed checks returned zero invalid records:

- Courier age outside 18–65.
- Courier rating outside 1–5.
- Vehicle condition outside the encoded values 0, 1, 2.
- Non-positive non-missing delivery distance.
- Non-missing delivery distance above 100 km.
- Non-positive actual delivery time.
- Non-positive predicted delivery time.

These checks validate the exported modelling sample against the project's stated cleaning rules. They do not prove that every source field is error-free or that the chosen plausibility ranges are universal business rules.

---

## 4. Model selection and final evaluation

Four regression approaches were compared using a validation split drawn from the 36,467-row training partition. The selection rule was the lowest validation MAE. HistGradientBoosting was selected, refitted on the full 36,467 training records, and evaluated once on the separate 9,117-row test set.

### 4.1 Validation comparison

| Model | Validation MAE (min) | Validation RMSE (min) | Validation R² |
|---|---:|---:|---:|
| HistGradientBoosting | **3.2111** | **4.0372** | **0.8153** |
| Random Forest | 3.2290 | 4.0954 | 0.8099 |
| Ridge Regression | 4.8287 | 6.0813 | 0.5808 |
| Mean baseline | 7.5269 | 9.3932 | approximately 0.000 |

HistGradientBoosting had the lowest validation MAE, narrowly ahead of Random Forest. The final test metrics were then computed on the separate holdout set, not on the validation split.

### 4.2 Final held-out test results

| Metric | Final result |
|---|---:|
| Selected model | HistGradientBoosting |
| Training rows used for final fit | 36,467 |
| Held-out test rows | 9,117 |
| Test MAE | 3.154 minutes |
| Test RMSE | 3.981 minutes |
| Test R² | 0.820 |
| Final fit time recorded in notebook | 2.561 seconds |

The recorded fit time is specific to the notebook runtime and should not be treated as a production latency or deployment benchmark.

### 4.3 Prediction error bands

The test predictions were grouped into non-overlapping absolute-error bands:

| Absolute error band | Orders | Share | Mean absolute error within band |
|---|---:|---:|---:|
| 0–2 minutes (inclusive) | 3,471 | 38.07% | 0.99 min |
| >2–5 minutes | 3,879 | 42.55% | 3.34 min |
| >5–10 minutes | 1,625 | 17.82% | 6.55 min |
| >10 minutes | 142 | 1.56% | 12.29 min |

A total of **7,350 orders (80.62%)** had predictions within five minutes. The remaining **1,767 orders (19.38%)** had errors greater than five minutes.

### 4.4 Prediction direction

Using a 0.001-minute tolerance to classify near-exact predictions:

| Direction | Orders | Share | Mean absolute error | Average signed error | Average actual time |
|---|---:|---:|---:|---:|---:|
| Underprediction | 4,286 | 47.01% | 3.26 min | +3.26 min | 29.62 min |
| Overprediction | 4,828 | 52.96% | 3.06 min | -3.06 min | 23.34 min |
| Near-exact | 3 | 0.03% | 0.00 min | 0.00 min | 25.00 min |

Overprediction occurred slightly more frequently than underprediction. Underpredicted deliveries had a higher average actual delivery duration (29.62 versus 23.34 minutes). This is a descriptive difference between error groups, not proof that longer deliveries cause underprediction.

### 4.5 Prediction direction by traffic category

| Traffic category | Orders | Underpredicted | Overpredicted | Underprediction share | Mean signed error | MAE |
|---|---:|---:|---:|---:|---:|---:|
| Low | 3,118 | 1,509 | 1,608 | 48.40% | -0.04 min | 2.67 min |
| Medium | 2,102 | 1,007 | 1,094 | 47.91% | -0.05 min | 3.19 min |
| Jam | 2,890 | 1,322 | 1,567 | 45.74% | -0.12 min | 3.48 min |
| Unknown | 119 | 53 | 66 | 44.54% | -0.51 min | 6.15 min |
| High | 888 | 395 | 493 | 44.48% | -0.16 min | 3.28 min |

Overprediction was more frequent than underprediction in every traffic category. Low traffic had the highest underprediction share, while Jam had the highest MAE among known traffic categories. The Unknown category had the highest MAE overall, but its sample was much smaller.

### 4.6 Permutation feature importance

Permutation importance was calculated on a reproducible sample of up to 2,500 held-out test records, using negative MAE scoring and three repeats. The values below represent the mean increase in MAE when a feature is shuffled; larger positive values indicate greater model reliance in this evaluation.

| Feature | Mean importance |
|---|---:|
| Weather conditions | 1.8183 |
| Road traffic density | 1.7806 |
| Delivery person ratings | 1.3525 |
| Distance (km) | 1.3155 |
| Delivery person age | 1.2361 |
| Vehicle condition | 0.9866 |
| Multiple deliveries | 0.5838 |
| Festival indicator | 0.1765 |
| City category | 0.0768 |
| Distance missing indicator | 0.0397 |
| Order-hour sine | 0.0206 |
| Order-hour cosine | 0.0205 |
| Order-day sine | 0.0045 |
| Vehicle type | -0.0015 |
| Order-day cosine | -0.0024 |
| Order type | approximately -0.003 |

Permutation importance is a measure of predictive reliance, **not causation**. Small negative values indicate that shuffling the feature marginally improved the score in this sample and should be interpreted as little or no positive contribution under this evaluation. The importance estimates are based on a sample and three repeats, not an exhaustive causal analysis.

---

## 5. Operational findings from SQL analysis

All segment-level results below are calculated from the 9,117 held-out test predictions. MAE means average absolute prediction error in minutes. Percentages are shares of the full test sample unless stated otherwise.

### 5.1 Traffic density

| Traffic | Orders | Share | Average actual delivery | MAE |
|---|---:|---:|---:|---:|
| Jam | 2,890 | 31.70% | **31.21 min** | 3.48 min |
| High | 888 | 9.74% | 27.21 min | 3.28 min |
| Medium | 2,102 | 23.06% | 26.82 min | 3.19 min |
| Unknown | 119 | 1.31% | 26.12 min | 6.15 min |
| Low | 3,118 | 34.20% | **21.13 min** | 2.67 min |

Jam traffic averaged **10.08 minutes longer** than Low traffic. Jam was also the highest-MAE known traffic category. These averages are observational and are not adjusted for weather, distance, city or other characteristics.

### 5.2 Weather conditions

| Weather | Orders | Share | Average actual delivery | MAE |
|---|---:|---:|---:|---:|
| Fog | 1,497 | 16.42% | **29.32 min** | 3.01 min |
| Cloudy | 1,519 | 16.66% | 28.70 min | 2.82 min |
| Windy | 1,534 | 16.83% | 26.27 min | 3.34 min |
| Unknown | 123 | 1.35% | 25.98 min | 6.08 min |
| Sandstorms | 1,489 | 16.33% | 25.93 min | 3.24 min |
| Stormy | 1,480 | 16.23% | 25.82 min | 3.20 min |
| Sunny | 1,475 | 16.18% | **21.64 min** | 3.08 min |

Fog averaged **7.68 minutes longer** than Sunny conditions. Unknown weather had a relatively high MAE, but the group contained only 123 orders.

### 5.3 Combined traffic and weather

The executed interaction query retained combinations with at least 10 records. It returned 25 combinations covering 9,113 records; four records in smaller groups were excluded by the minimum-group threshold.

| Weather | Traffic | Orders | Average actual delivery | MAE |
|---|---|---:|---:|---:|
| Fog | Jam | 507 | **37.06 min** | 3.70 min |
| Cloudy | Jam | 478 | 36.46 min | 3.23 min |
| Windy | Jam | 478 | 30.50 min | 3.66 min |
| Sandstorms | Jam | 475 | 30.28 min | 3.40 min |
| Stormy | Jam | 469 | 30.03 min | 3.34 min |
| Sunny | Medium | 313 | **19.98 min** | 2.82 min |

Fog + Jam was the slowest displayed combination. Sunny + Medium was the fastest displayed combination. The difference between their averages was 17.08 minutes. These are segment averages; they do not isolate the independent effect of either factor.

### 5.4 Haversine distance bands

The distance analysis excluded the 811 records with missing distance and therefore covered **8,306 orders**. Distance is a straight-line Haversine estimate between coordinates, not road-route distance.

| Distance band | Orders | Average actual delivery | MAE |
|---|---:|---:|---:|
| 0–5 km | 2,257 | 22.32 min | 2.75 min |
| 5–10 km | 2,192 | 24.45 min | 3.08 min |
| 10–15 km | 2,293 | **29.86 min** | 3.30 min |
| 15+ km | 1,564 | 29.72 min | 3.28 min |

Average delivery duration increased across the first three bands, then was slightly lower in the 15+ km band. The relationship is therefore not strictly increasing across every band. MAE was higher in the longer-distance groups than in the 0–5 km group.

### 5.5 Recorded `multiple_deliveries` categories

The analysis preserves the numeric source values and does not reinterpret them as a verified operational definition.

| Recorded value | Orders | Share | Average actual delivery | MAE |
|---|---:|---:|---:|---:|
| 0.0 | 2,812 | 30.84% | 22.84 min | 3.13 min |
| 1.0 | 5,623 | 61.68% | 26.90 min | 3.20 min |
| 2.0 | 404 | 4.43% | 40.16 min | 2.82 min |
| 3.0 | 75 | 0.82% | 47.67 min | 2.16 min |
| Unknown | 203 | 2.23% | 21.90 min | 3.16 min |

The higher recorded categories had higher average delivery times in this sample. Category 3 contained only 75 records. The exact business meaning of the encoded values should be confirmed from the source documentation before translating them into operational language such as number of simultaneous orders.

### 5.6 Courier ratings

The grouped analysis used the following bands: below 3.5; 3.5–3.9; 4.0–4.4; 4.5–5.0; and Unknown.

| Rating band | Orders | Share | Average actual delivery | MAE |
|---|---:|---:|---:|---:|
| Below 3.5 | 59 | 0.65% | 33.86 min | 2.91 min |
| 3.5–3.9 | 251 | 2.75% | **37.63 min** | 2.89 min |
| 4.0–4.4 | 1,352 | 14.83% | 34.53 min | 3.07 min |
| 4.5–5.0 | 7,083 | 77.69% | 24.25 min | 3.08 min |
| Unknown | 372 | 4.08% | 26.51 min | 5.14 min |

The 4.5–5.0 group represented most of the sample and had a lower average delivery duration than the 4.0–4.4 group. These are unadjusted associations and do not demonstrate that ratings cause faster delivery. The Below 3.5 group is small.

### 5.7 City categories

The `City` field represents dataset categories rather than named geographic cities.

| City category | Orders | Share | Average actual delivery | MAE |
|---|---:|---:|---:|---:|
| Semi-Urban | 42 | 0.46% | **49.26 min** | 2.91 min |
| Metropolitan | 6,846 | 75.09% | 27.24 min | 3.16 min |
| Urban | 1,986 | 21.78% | 22.97 min | 3.15 min |
| Unknown | 243 | 2.67% | 22.88 min | 2.94 min |

Semi-Urban had the highest average, but only 42 records were present. It should be treated as a small-sample signal for further investigation, not as a stable estimate of typical Semi-Urban delivery performance.

### 5.8 Order category

| Order category | Orders | Share | Average actual delivery | MAE |
|---|---:|---:|---:|---:|
| Buffet | 2,221 | 24.36% | 26.44 min | 3.11 min |
| Meal | 2,311 | 25.35% | 26.37 min | 3.20 min |
| Drinks | 2,289 | 25.11% | 26.26 min | 3.11 min |
| Snack | 2,296 | 25.18% | 26.11 min | 3.19 min |

Average delivery time varied by only **0.33 minutes** across order categories. The order-category permutation importance was approximately -0.003, indicating negligible positive predictive contribution in that feature-importance evaluation.

### 5.9 Vehicle category

| Vehicle category | Orders | Share | Average actual delivery | MAE |
|---|---:|---:|---:|---:|
| Motorcycle | 5,302 | 58.16% | 27.61 min | 3.24 min |
| Electric scooter | 735 | 8.06% | 24.54 min | 3.24 min |
| Scooter | 3,062 | 33.59% | 24.45 min | 2.97 min |
| Bicycle | 18 | 0.20% | 24.39 min | 5.57 min |

Motorcycles represented the largest share of the test sample. The bicycle group is too small for a strong general conclusion; its MAE of 5.57 minutes is based on only 18 records.

### 5.10 Festival indicator

| Source Festival value | Orders | Share | Average actual delivery | MAE |
|---|---:|---:|---:|---:|
| Yes | 173 | 1.90% | **45.32 min** | 2.87 min |
| No | 8,908 | 97.71% | 25.99 min | 3.16 min |
| Unknown | 36 | 0.39% | 11.28 min | 1.80 min |

The Yes group averaged 19.33 minutes more than the No group, but it contained only 173 orders. The field is a source indicator, not a separately verified event calendar or measure of festival demand. The result should be investigated alongside other conditions and not described as evidence that festivals cause delays.

---

## 6. Severe prediction errors by operating conditions

A severe prediction error was defined for this analysis as an absolute error **greater than 10 minutes**. The query required at least 30 records in a weather-traffic group. It identified 142 severe errors across the displayed groups, reconciling with the overall error segmentation.

| Weather | Traffic | Orders | Errors >10 min | Severe-error rate | Average severe error |
|---|---|---:|---:|---:|---:|
| Unknown | Unknown | 119 | 25 | **21.01%** | 12.55 min |
| Sandstorms | High | 149 | 10 | 6.71% | 12.39 min |
| Windy | High | 163 | 10 | 6.13% | 11.94 min |
| Stormy | High | 137 | 7 | 5.11% | 11.13 min |
| Sunny | High | 142 | 4 | 2.82% | 17.28 min |
| Fog | Jam | 507 | 13 | 2.56% | 12.50 min |
| Windy | Jam | 478 | 12 | 2.51% | 11.97 min |
| Sunny | Jam | 482 | 12 | 2.49% | 12.20 min |

The Unknown + Unknown group had the highest severe-error rate, with 25 of 119 orders exceeding the ten-minute threshold. Among known weather/traffic combinations, Sandstorms + High and Windy + High had the highest displayed rates. Fog + Jam had the largest severe-error count among the known combinations shown (13).

A high severe-error rate in a small or incomplete-information segment is a monitoring signal, not proof of a specific cause. Average severe-error magnitude should also be considered alongside the rate: for example, Sunny + High had four severe errors with an average magnitude of 17.28 minutes.

---

## 7. Practical recommendations

The following recommendations are proposed from the descriptive and predictive findings. They are hypotheses for operational follow-up, not causal conclusions established by this analysis.

1. **Improve completeness of operational inputs.** Prioritise the availability and validation of traffic, weather, courier-rating and distance fields. Unknown traffic/weather records had materially higher MAE and a high severe-error rate in the Unknown + Unknown group.
2. **Monitor high-risk operating segments.** Track prediction MAE and the share of errors above ten minutes across traffic-weather combinations, especially High traffic with Sandstorms, Windy or Stormy conditions. Review sample counts alongside rates.
3. **Review Jam-traffic delivery performance.** Jam traffic had the highest average actual delivery duration and the highest MAE among known traffic categories. Further analysis controlling for distance, weather and city category would help determine which factors explain the difference.
4. **Investigate distance-related error patterns.** Prediction MAE was lower in the 0–5 km band than in longer distance bands. Road-route distance or travel-time features could be evaluated in a future model iteration, if reliable route data is available.
5. **Review multi-delivery source encoding.** Higher recorded values were associated with longer average delivery durations, but the operational meaning of the codes must be confirmed before designing workload interventions.
6. **Investigate the Semi-Urban and Bicycle segments with caution.** Their sample sizes were small (42 and 18 records respectively). More representative data is needed before making segment-specific decisions.
7. **Track more than overall MAE.** Retain MAE, RMSE and R², but also monitor underprediction/overprediction rates, error bands and severe-error rates by operating segment. Overall bias near zero can hide differences between subgroups.
8. **Treat the five-minute tolerance as a project evaluation threshold.** The 80.62% within-five-minute result is not an on-time-delivery SLA or a guarantee to customers. A real operational SLA would require a defined promised-delivery timestamp and outcome data.

---

## 8. Limitations and interpretation cautions

- **Third-party data provenance:** The public dataset is attributed to Zomato delivery operations, but an official company data release has not been independently verified.
- **Test-sample scope:** SQL and dashboard segment findings describe 9,117 held-out test rows, not the full 45,584-row source dataset.
- **Observational analysis:** Grouped averages and error rates are descriptive. They do not isolate causal effects or adjust for confounding variables.
- **Small groups:** Results for Bicycle (18), Semi-Urban (42), Below 3.5 courier rating (59), and some other small segments are unstable and should not be generalised.
- **Missing information:** Missing operational fields may affect model performance and segment interpretation. Unknown groups are not necessarily homogeneous.
- **Distance definition:** `distance_km` is a straight-line Haversine estimate, not a road-route distance or travel distance.
- **Encoded categories:** The exact operational semantics of numeric `multiple_deliveries` values and some source categories should be confirmed from source documentation before translating them into business policy.
- **Festival indicator:** The dataset's Festival field is not a validated calendar of actual events or a direct measure of demand/congestion.
- **Feature importance:** Permutation importance measures model reliance on a sample; it does not identify causal drivers.
- **Thresholds:** Absolute error >10 minutes and within ±5 minutes are analytical thresholds for this project, not published service-level commitments.
- **Model generalisation:** The final metrics describe one held-out test split. Production performance, data drift, prediction latency and real-world business impact have not been tested.

---

## 9. Reproducibility and project files

The findings are supported by the following repository components:

| Component | Project file | Purpose |
|---|---|---|
| Data audit | `notebooks/01_data_ingestion_quality_audit.ipynb` | Source inspection and initial data-quality assessment |
| Prediction modelling | `notebooks/02_delivery_time_prediction.ipynb` | Feature preparation, validation comparison, final test evaluation and exports |
| SQL analysis | `sql/business_analysis.sql` | SQLite data-quality, operational and error-segmentation queries |
| Database loader | `scripts/load_predictions.py` | Loads the test-prediction CSV into SQLite |
| Power BI report | `dashboard/Fulfillment_Pulse.pbix` | Executive Overview and Predictive Performance pages |
| Model metrics | `data/exports/fulfillment_pulse_model_metrics.csv` | Final test-set metrics |
| Validation comparison | `data/exports/fulfillment_pulse_validation_comparison.csv` | Model selection comparison |
| Feature importance | `data/exports/fulfillment_pulse_permutation_importance.csv` | Permutation importance results |
| Test predictions | `data/exports/fulfillment_pulse_test_predictions.csv` | Row-level predictions used in SQL and Power BI |

The project should be reproduced by obtaining the public source data, running the notebooks in order, loading the exported test predictions into SQLite, and refreshing the Power BI report with the corresponding exports. Do not commit raw source data, the SQLite database or unnecessary row-level exports to a public repository unless their redistribution terms and project policy have been checked.

---

## 10. Conclusion

FULFILLMENT PULSE combines a reproducible data-preparation and regression workflow with SQL-based operational analysis and a Power BI dashboard. HistGradientBoosting achieved a test MAE of 3.154 minutes, RMSE of 3.981 minutes and R² of 0.820 on 9,117 held-out records; 80.62% of its predictions were within five minutes of actual delivery times.

The SQL analysis identified meaningful differences across traffic, weather, distance and several operational categories. It also showed that overall model metrics alone do not describe every segment: missing-condition groups and certain weather-traffic combinations had higher severe-error rates. The results provide a basis for further investigation, improved input-data completeness and segment-level model monitoring, while remaining appropriately limited to descriptive evidence from a public test sample.
