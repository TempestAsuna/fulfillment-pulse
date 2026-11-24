-- FULFILLMENT PULSE
-- SQLite schema for the 9,117-row held-out prediction export from Notebook 02.
-- The table includes model inputs plus actual/predicted delivery-time results.

DROP TABLE IF EXISTS delivery_predictions;

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
);

CREATE INDEX idx_delivery_traffic
    ON delivery_predictions (Road_traffic_density);

CREATE INDEX idx_delivery_weather
    ON delivery_predictions (Weather_conditions);

CREATE INDEX idx_delivery_city
    ON delivery_predictions (City);
