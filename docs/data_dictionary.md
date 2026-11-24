# Data dictionary — prediction export

The SQL/Power BI input `fulfillment_pulse_test_predictions.csv` has 20 columns. The export is built from the model feature frame and four prediction/result columns. It does not include the original order ID or courier ID. The SQL loader creates its own `row_id` solely to identify imported rows.

| Column | Type | Meaning |
|---|---|---|
| `Delivery_person_Age` | Numeric | Courier age after project cleaning rules; invalid/out-of-range values treated as missing. |
| `Delivery_person_Ratings` | Numeric | Courier rating on the source 1–5 scale, after validity checks. |
| `Vehicle_condition` | Numeric | Source vehicle-condition code (expected levels 0, 1, 2). |
| `multiple_deliveries` | Numeric | Source indicator/count for multiple concurrent deliveries. |
| `distance_km` | Numeric | Haversine straight-line distance estimate in kilometres; may be missing. |
| `distance_missing` | Numeric / binary | Indicator that route-distance estimate is unavailable. |
| `order_hour_sin` | Numeric | Sine-transformed cyclical order-hour feature. |
| `order_hour_cos` | Numeric | Cosine-transformed cyclical order-hour feature. |
| `order_dow_sin` | Numeric | Sine-transformed cyclical day-of-week feature. |
| `order_dow_cos` | Numeric | Cosine-transformed cyclical day-of-week feature. |
| `Weather_conditions` | Text | Weather category; missing source values are handled by the pipeline and shown as Unknown in aggregate reporting. |
| `Road_traffic_density` | Text | Traffic-density category. |
| `Type_of_order` | Text | Food/order category from the source. |
| `Type_of_vehicle` | Text | Delivery vehicle category from the source. |
| `Festival` | Text | Festival indicator/category from the source. |
| `City` | Text | City category from the source dataset. |
| `actual_minutes` | Numeric | Observed delivery duration in minutes (`Time_taken (min)`). |
| `predicted_minutes` | Numeric | HistGradientBoosting prediction for the row, in minutes. |
| `error_minutes` | Numeric | Signed error: actual minus predicted. Positive means underprediction; negative means overprediction. |
| `absolute_error_minutes` | Numeric | Absolute difference between actual and predicted duration, in minutes. |

## Row identifiers

The export intentionally excludes original identifiers from the modelling feature set. `row_id` in SQLite is an auto-incrementing import row number, not an original order ID and not a durable business identifier.
