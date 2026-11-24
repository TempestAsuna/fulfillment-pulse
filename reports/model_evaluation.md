# Model evaluation

## Dataset split

- Source-training split: 36,467 records.
- Internal training partition: 29,173 records.
- Validation partition: 7,294 records.
- Separate source test holdout: 9,117 records.

The validation partition is used for model selection. The selected pipeline is refitted on all 36,467 source-training rows and evaluated on the separate 9,117-row test split.

## Validation model comparison

| Model | MAE (min) | RMSE (min) | R² |
|---|---:|---:|---:|
| Mean baseline | 7.527 | 9.393 | approximately 0.000 |
| Ridge Regression | 4.829 | 6.081 | 0.581 |
| Random Forest | 3.229 | 4.095 | 0.810 |
| HistGradientBoosting | **3.211** | **4.037** | **0.815** |

HistGradientBoosting was selected because it achieved the lowest validation MAE. Its margin over Random Forest was small, so the result should be described as a modest validation improvement, not a dramatic performance gap.

## Final test-set performance

| Metric | Result |
|---|---:|
| Selected model | HistGradientBoosting |
| MAE | 3.154 minutes |
| RMSE | 3.981 minutes |
| R² | 0.820 |
| Predictions with absolute error <= 5 minutes | 80.6% |
| Median absolute error | approximately 2.68 minutes |
| 90th percentile absolute error | approximately 6.35 minutes |

## Interpretation

- MAE of 3.154 minutes means the mean absolute difference between predicted and observed duration is about 3.15 minutes on the test sample.
- RMSE is higher than MAE because larger errors receive more weight.
- R² of 0.820 indicates that the model explains about 82% of target variance in this test sample; it does not mean 82% of predictions are correct.
- The 80.6% statistic is a within-five-minute prediction tolerance, not an operational delivery SLA.

## Permutation importance

The top individual model-reliance measures in the notebook are Weather_conditions (1.8183), Road_traffic_density (1.7806), Delivery_person_Ratings (1.3525), distance_km (1.3155), Delivery_person_Age (1.2361), Vehicle_condition (0.9866) and multiple_deliveries (0.5838). Values represent increases in MAE after shuffling a feature. They are not causal effects.

## Evaluation caveat

Permutation importance was computed using a sample of the final test set after the final performance evaluation. Treat the test set as spent for further model selection/tuning; a fresh holdout or cross-validation design would be needed for additional model comparisons.
