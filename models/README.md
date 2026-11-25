# Model artifacts

The repository includes `fulfillment_pulse_eta_model.joblib`, exported by Notebook 02. It contains the fitted preprocessing/model pipeline selected using validation MAE (HistGradientBoostingRegressor).

The artifact is a Python/joblib pickle-based file. Load it only from a trusted source and in a compatible Python/scikit-learn environment. It is not a standalone web service or deployed endpoint.

To regenerate the artifact, run Notebook 02 and download the model from the `fulfillment_pulse_outputs/` export bundle.
