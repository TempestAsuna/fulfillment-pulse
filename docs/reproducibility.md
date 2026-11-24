# Reproducibility guide

## 1. Run the notebooks

1. Open `notebooks/01_data_ingestion_quality_audit.ipynb` in Google Colab or Jupyter and run all cells. This performs the initial source audit.
2. Open `notebooks/02_delivery_time_prediction.ipynb` and run all cells from top to bottom. It independently reloads train/test splits, prepares features, compares models, selects HistGradientBoosting using validation MAE, evaluates on the held-out source test split and exports artifacts.
3. Notebook 02 creates a `fulfillment_pulse_outputs/` directory containing the fitted model, metrics, validation comparison, held-out predictions and permutation importance. Download the exported output ZIP from Colab.

## 2. Use the prediction CSV

Extract `fulfillment_pulse_test_predictions.csv` and place it under `data/exports/`. It should contain 9,117 rows and the 20 headers listed in `data_dictionary.md`.

## 3. Rebuild the SQLite database

From the repository root:

```bash
python scripts/load_predictions.py "data/exports/fulfillment_pulse_test_predictions.csv"
```

The script validates the required columns, loads the rows into `delivery_predictions`, creates indexes and verifies the row count. It creates/replaces `fulfillment_pulse.db` in the current working directory. The database is ignored by Git.

## 4. Run the SQL analysis

Open `sql/business_analysis.sql` in a SQLite client or VS Code SQLite extension connected to `fulfillment_pulse.db`. Execute the audit queries first, then the business analysis queries. Save only aggregated, reproducible findings into `reports/business_insights.md`.

## 5. Power BI

Open the final PBIX file in Power BI Desktop and refresh the prediction CSV source if needed. Keep the Executive Overview and Predictive Performance pages. The screenshot previews in `dashboard/screenshots/` are static and do not replace the PBIX file.

## 6. Reconciliation checks

Compare SQL and Power BI on the same 9,117-row export. Key reference results are:

- Count: 9,117
- Average actual delivery time: approximately 26.29 minutes
- Average predicted delivery time: approximately 26.38 minutes
- Mean absolute error: approximately 3.154 minutes
- Mean signed error: approximately -0.08 minutes
- Predictions within ±5 minutes: approximately 80.6%

Minor display differences may come from rounding. Do not compare test-sample SQL values to source-training summaries without labelling the populations clearly.
