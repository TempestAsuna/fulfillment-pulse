# Project structure and file guide

This guide describes the files currently included in the public repository and identifies the data artifacts that must be generated locally.

```text
FULFILLMENT-PULSE/
├── README.md
├── .gitignore
├── requirements.txt
├── data/
│   ├── README.md
│   ├── raw/.gitkeep
│   ├── processed/.gitkeep
│   └── exports/
│       ├── README.md
│       └── .gitkeep
├── docs/
│   ├── README.md
│   ├── data_dictionary.md
│   ├── data_sources.md
│   ├── methodology.md
│   ├── project_structure.md
│   └── reproducibility.md
├── models/
│   ├── README.md
│   └── fulfillment_pulse_eta_model.joblib
├── notebooks/
│   ├── 01_data_ingestion_quality_audit.ipynb
│   └── 02_delivery_time_prediction.ipynb
├── notebooks/
│   ├── 01_data_ingestion_quality_audit.ipynb
│   └── 02_delivery_time_prediction.ipynb
├── reports/
│   ├── business_insights.md
│   └── model_evaluation.md
├── scripts/
│   └── load_predictions.py
├── sql/
│   ├── README.md
│   ├── business_analysis.sql
│   └── schema.sql
└── dashboard/
    ├── README.md
    ├── PowerBI/
    │   └── PowerBI.pbix
    └── screenshots/
        ├── executive_overview.png
        └── predictive_performance.png
```

## Root files

- `README.md`: project overview, goals, model results, business findings, dashboard previews and reproduction steps.
- `requirements.txt`: Python packages used by the notebooks.
- `.gitignore`: excludes local environments, SQLite databases, source/derived CSV exports, and temporary outputs.

## Notebooks

- `notebooks/01_data_ingestion_quality_audit.ipynb`: inspects the public source data, schema, missingness, suspicious values, coordinates and delivery-time distribution.
- `notebooks/02_delivery_time_prediction.ipynb`: prepares modelling data, engineers features, compares regression models, selects using validation MAE, evaluates once on the separate source test split, calculates permutation importance and exports model/evaluation artifacts.

The committed notebooks retain execution outputs so reviewers can inspect the recorded workflow without immediately rerunning every cell.

## Data directories

- `data/raw/`: optional local source downloads; not committed.
- `data/processed/`: optional local intermediate files; not committed.
- `data/exports/`: local Notebook 02 CSV outputs used by the SQL loader and Power BI refresh. The prediction CSVs are ignored by Git; only the directory README and placeholder are committed.

## Scripts and SQL

- `scripts/load_predictions.py`: standard-library CSV importer. It validates the 20 expected input fields, loads rows into SQLite table `delivery_predictions`, creates indexes and verifies the loaded count.
- `sql/schema.sql`: table schema and indexes.
- `sql/business_analysis.sql`: 20 core query sections covering record integrity, missingness, feature consistency, numerical validity, overall KPIs, operational segments and prediction-error analysis, plus an optional 30-minute threshold query.
- `sql/README.md`: SQL scope, query index, load instructions and interpretation rules.

## Model and dashboard artifacts

- `models/fulfillment_pulse_eta_model.joblib`: committed HistGradientBoosting preprocessing/model pipeline exported by Notebook 02. It is a trusted project artifact; only load it in a compatible environment.
- `dashboard/PowerBI/PowerBI.pbix`: committed two-page Power BI report.
- `dashboard/screenshots/`: static PNG previews for GitHub visitors who cannot open PBIX in the browser.

## Reports and documentation

- `reports/model_evaluation.md`: validation comparison, final test metrics and model interpretation.
- `reports/business_insights.md`: descriptive operational findings and prediction-error analysis based on the held-out test sample.
- `docs/methodology.md`: task definition, data cleaning, feature engineering, model selection and evaluation approach.
- `docs/data_dictionary.md`: definitions and types of the 20 CSV input fields.
- `docs/data_sources.md`: dataset mirror, attribution caveat, derived-data and metric definitions.
- `docs/reproducibility.md`: notebook, export, SQLite and Power BI refresh workflow.

## Generated locally; excluded from Git by default

- Raw source data and processed intermediate datasets.
- `data/exports/*.csv` and `data/exports/*.parquet`, including the row-level test prediction export.
- `fulfillment_pulse.db` and SQLite journal/WAL files.
- Virtual environments, Python caches, notebook checkpoints and temporary ZIP outputs.

The PBIX and joblib artifacts are committed in this repository. Confirm data-source terms before redistributing artifacts that may embed source or derived records.
