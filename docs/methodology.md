# Methodology

## Business question

Can total food-delivery time be estimated from information assumed to be available around order assignment, before the delivery is completed? Which operational variables does the model rely on, and how does performance vary across delivery conditions?

## Notebook 01 — ingestion and quality audit

The first notebook loads the public Hugging Face dataset and combines its train/test splits for descriptive audit only. It inspects schema, data types, missingness, suspicious values, location coordinates, delivery-time distribution and category counts. It saves a source snapshot and quality report. It does not create the modelling dataset.

The source audit reports 45,584 records and 20 original source columns. Examples of observed missingness include courier ratings (1,908; 4.19%), courier age (1,854; 4.07%), order time (1,731; 3.80%), city (1,200; 2.63%), multiple deliveries (993; 2.18%), weather (616; 1.35%) and traffic density (601; 1.32%). The audit flags implausible values rather than automatically deleting them.

## Notebook 02 — preparation and modelling

Notebook 02 reloads source train/test splits separately. The source test split remains held out until final evaluation.

Key preparation rules documented in the notebook:

- Standardise blank and text placeholders such as `NaN`, `None`, `null`, `na` and `n/a` as missing.
- Treat courier ages outside the chosen plausibility interval and ratings outside 1–5 as missing, not automatically as deleted rows.
- Check vehicle-condition values against the expected source levels 0, 1 and 2.
- Use broad India coordinate screening bounds for coordinate validity; these are screening assumptions, not precise geocoding.
- Calculate straight-line distance with the Haversine formula; unavailable/implausible coordinate pairs become missing distance plus a missingness indicator.
- Derive cyclical order-hour and weekday features from `Time_Orderd`.
- Exclude `Time_Order_picked` because it occurs after order placement and may not be available at the assumed prediction time.
- Exclude IDs and raw coordinates from model predictors.
- Impute numeric/categorical features inside the scikit-learn preprocessing pipeline; encode categorical variables with one-hot encoding.

## Model predictors

The notebook uses 16 predictors:

**Numeric (10):** `Delivery_person_Age`, `Delivery_person_Ratings`, `Vehicle_condition`, `multiple_deliveries`, `distance_km`, `distance_missing`, `order_hour_sin`, `order_hour_cos`, `order_dow_sin`, `order_dow_cos`.

**Categorical (6):** `Weather_conditions`, `Road_traffic_density`, `Type_of_order`, `Type_of_vehicle`, `Festival`, `City`.

## Model comparison and selection

A mean baseline, Ridge Regression, Random Forest and HistGradientBoosting are compared. The 36,467-row source training split is divided into 29,173 training records and 7,294 validation records. The selected model is based on the lowest validation MAE. HistGradientBoosting achieved validation MAE 3.211 minutes, narrowly ahead of Random Forest at 3.229 minutes.

After selection, the pipeline is refitted on all 36,467 source-training rows and evaluated once on the separate 9,117-row source test split.

## Evaluation

Final source-test metrics: MAE 3.154 minutes, RMSE 3.981 minutes and R² 0.820. A reported 80.6% of test predictions have absolute error <=5 minutes.

Permutation importance is computed on a sample of the test set, using an increase in MAE when a feature is shuffled. It measures model reliance, not causal effect. Because the test set was used for this explanatory analysis, it should not be reused as an untouched benchmark for further model tuning.
