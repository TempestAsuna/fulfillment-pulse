-- ============================================================================
-- FULFILLMENT PULSE | SQL BUSINESS ANALYSIS
-- SQL dialect : SQLite
-- Table       : delivery_predictions
-- Scope       : 9,117 held-out test predictions (not the full source dataset)
-- Error sign  : error_minutes = actual_minutes - predicted_minutes
--               Positive = underprediction; negative = overprediction.
--
-- Queries 01-20 consolidate the analyses run during the project.
-- Query 21 is an optional additional threshold analysis and has not yet been
-- validated against a result screenshot. A 30-minute threshold is analytical,
-- not a published delivery SLA.
-- ============================================================================

-- ============================================================================
-- QUERY 01: RECORD INTEGRITY AND DATASET OVERVIEW
-- Purpose: Confirm row count, identifier integrity, and target completeness.
-- ============================================================================
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT row_id) AS unique_row_ids,
    COUNT(row_id) - COUNT(DISTINCT row_id) AS duplicate_non_null_row_ids,
    SUM(CASE WHEN row_id IS NULL OR TRIM(CAST(row_id AS TEXT)) = '' THEN 1 ELSE 0 END)
        AS missing_row_ids,
    SUM(CASE WHEN actual_minutes IS NULL THEN 1 ELSE 0 END) AS missing_actual_minutes,
    SUM(CASE WHEN predicted_minutes IS NULL THEN 1 ELSE 0 END) AS missing_predicted_minutes,
    ROUND(MIN(actual_minutes), 2) AS minimum_actual_minutes,
    ROUND(MAX(actual_minutes), 2) AS maximum_actual_minutes
FROM delivery_predictions;


-- ============================================================================
-- QUERY 02: MISSING-VALUE AUDIT ACROSS ALL 21 COLUMNS
-- Purpose: Count NULL and blank-string values in each exported column.
-- Note: Numeric fields are cast to TEXT so the same blank check can be used.
-- ============================================================================
WITH missing_counts AS (
    SELECT 'row_id' AS column_name,
           SUM(CASE WHEN row_id IS NULL OR TRIM(CAST(row_id AS TEXT)) = '' THEN 1 ELSE 0 END) AS missing_count
    FROM delivery_predictions

    UNION ALL
    SELECT 'Delivery_person_Age',
           SUM(CASE WHEN Delivery_person_Age IS NULL OR TRIM(CAST(Delivery_person_Age AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'Delivery_person_Ratings',
           SUM(CASE WHEN Delivery_person_Ratings IS NULL OR TRIM(CAST(Delivery_person_Ratings AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'Vehicle_condition',
           SUM(CASE WHEN Vehicle_condition IS NULL OR TRIM(CAST(Vehicle_condition AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'multiple_deliveries',
           SUM(CASE WHEN multiple_deliveries IS NULL OR TRIM(CAST(multiple_deliveries AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'distance_km',
           SUM(CASE WHEN distance_km IS NULL OR TRIM(CAST(distance_km AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'distance_missing',
           SUM(CASE WHEN distance_missing IS NULL OR TRIM(CAST(distance_missing AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'order_hour_sin',
           SUM(CASE WHEN order_hour_sin IS NULL OR TRIM(CAST(order_hour_sin AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'order_hour_cos',
           SUM(CASE WHEN order_hour_cos IS NULL OR TRIM(CAST(order_hour_cos AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'order_dow_sin',
           SUM(CASE WHEN order_dow_sin IS NULL OR TRIM(CAST(order_dow_sin AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'order_dow_cos',
           SUM(CASE WHEN order_dow_cos IS NULL OR TRIM(CAST(order_dow_cos AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'Weather_conditions',
           SUM(CASE WHEN Weather_conditions IS NULL OR TRIM(CAST(Weather_conditions AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'Road_traffic_density',
           SUM(CASE WHEN Road_traffic_density IS NULL OR TRIM(CAST(Road_traffic_density AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'Type_of_order',
           SUM(CASE WHEN Type_of_order IS NULL OR TRIM(CAST(Type_of_order AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'Type_of_vehicle',
           SUM(CASE WHEN Type_of_vehicle IS NULL OR TRIM(CAST(Type_of_vehicle AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'Festival',
           SUM(CASE WHEN Festival IS NULL OR TRIM(CAST(Festival AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'City',
           SUM(CASE WHEN City IS NULL OR TRIM(CAST(City AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'actual_minutes',
           SUM(CASE WHEN actual_minutes IS NULL OR TRIM(CAST(actual_minutes AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'predicted_minutes',
           SUM(CASE WHEN predicted_minutes IS NULL OR TRIM(CAST(predicted_minutes AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'error_minutes',
           SUM(CASE WHEN error_minutes IS NULL OR TRIM(CAST(error_minutes AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions

    UNION ALL
    SELECT 'absolute_error_minutes',
           SUM(CASE WHEN absolute_error_minutes IS NULL OR TRIM(CAST(absolute_error_minutes AS TEXT)) = '' THEN 1 ELSE 0 END)
    FROM delivery_predictions
)
SELECT column_name, missing_count
FROM missing_counts
ORDER BY missing_count DESC, column_name;


-- ============================================================================
-- QUERY 03: ENGINEERED-FEATURE AND ERROR-FIELD CONSISTENCY
-- Purpose: Check distance flags, paired cyclic features, and error arithmetic.
-- Tolerance: 0.000001 minutes for floating-point comparisons.
-- ============================================================================
SELECT
    COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN distance_km IS NULL AND COALESCE(distance_missing, -1) <> 1 THEN 1
            WHEN distance_km IS NOT NULL AND COALESCE(distance_missing, -1) <> 0 THEN 1
            ELSE 0
        END
    ) AS distance_flag_mismatches,
    SUM(
        CASE
            WHEN order_hour_sin IS NULL AND order_hour_cos IS NOT NULL THEN 1
            WHEN order_hour_sin IS NOT NULL AND order_hour_cos IS NULL THEN 1
            ELSE 0
        END
    ) AS order_hour_pair_mismatches,
    SUM(
        CASE
            WHEN ABS(error_minutes - (actual_minutes - predicted_minutes)) > 0.000001 THEN 1
            ELSE 0
        END
    ) AS error_calculation_mismatches,
    SUM(
        CASE
            WHEN ABS(absolute_error_minutes - ABS(error_minutes)) > 0.000001 THEN 1
            ELSE 0
        END
    ) AS absolute_error_mismatches
FROM delivery_predictions;


-- ============================================================================
-- QUERY 04: NUMERICAL VALIDITY AUDIT
-- Purpose: Check numerical values against project validation rules.
-- Age/rating/vehicle bounds follow the cleaning assumptions in Notebook 2.
-- ============================================================================
SELECT
    'Courier age outside 18-65' AS validation_check,
    COUNT(*) AS invalid_records
FROM delivery_predictions
WHERE Delivery_person_Age IS NOT NULL
  AND (Delivery_person_Age < 18 OR Delivery_person_Age > 65)

UNION ALL
SELECT
    'Courier rating outside 1-5',
    COUNT(*)
FROM delivery_predictions
WHERE Delivery_person_Ratings IS NOT NULL
  AND (Delivery_person_Ratings < 1 OR Delivery_person_Ratings > 5)

UNION ALL
SELECT
    'Invalid vehicle condition',
    COUNT(*)
FROM delivery_predictions
WHERE Vehicle_condition IS NOT NULL
  AND Vehicle_condition NOT IN (0, 1, 2)

UNION ALL
SELECT
    'Non-positive delivery distance',
    COUNT(*)
FROM delivery_predictions
WHERE distance_km IS NOT NULL
  AND distance_km <= 0

UNION ALL
SELECT
    'Delivery distance above 100 km',
    COUNT(*)
FROM delivery_predictions
WHERE distance_km > 100

UNION ALL
SELECT
    'Non-positive actual delivery time',
    COUNT(*)
FROM delivery_predictions
WHERE actual_minutes <= 0

UNION ALL
SELECT
    'Non-positive predicted delivery time',
    COUNT(*)
FROM delivery_predictions
WHERE predicted_minutes <= 0;


-- ============================================================================
-- QUERY 05: OVERALL DELIVERY AND MODEL PERFORMANCE
-- Purpose: Calculate the core KPIs shown in the Power BI report.
-- Error definition: actual - predicted; negative mean bias indicates overprediction.
-- ============================================================================
SELECT
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_actual_delivery_time,
    ROUND(AVG(predicted_minutes), 2) AS avg_predicted_delivery_time,
    ROUND(AVG(error_minutes), 2) AS average_prediction_bias,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(
        100.0 * SUM(CASE WHEN absolute_error_minutes <= 5 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS predictions_within_5_min_pct,
    ROUND(MIN(actual_minutes), 2) AS minimum_delivery_time,
    ROUND(MAX(actual_minutes), 2) AS maximum_delivery_time
FROM delivery_predictions;


-- ============================================================================
-- QUERY 06: DELIVERY PERFORMANCE BY TRAFFIC DENSITY
-- Purpose: Compare order volume, delivery duration, and prediction error.
-- ============================================================================
SELECT
    COALESCE(NULLIF(TRIM(Road_traffic_density), ''), 'Unknown') AS traffic_condition,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_delivery_time,
    ROUND(AVG(predicted_minutes), 2) AS avg_predicted_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(AVG(error_minutes), 2) AS average_signed_error,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM delivery_predictions), 2)
        AS order_percentage
FROM delivery_predictions
GROUP BY traffic_condition
ORDER BY avg_delivery_time DESC;


-- ============================================================================
-- QUERY 07: DELIVERY PERFORMANCE BY WEATHER
-- Purpose: Compare delivery duration and prediction error by weather category.
-- ============================================================================
SELECT
    COALESCE(NULLIF(TRIM(Weather_conditions), ''), 'Unknown') AS weather_condition,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_delivery_time,
    ROUND(AVG(predicted_minutes), 2) AS avg_predicted_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(AVG(error_minutes), 2) AS prediction_bias,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM delivery_predictions), 2)
        AS order_percentage
FROM delivery_predictions
GROUP BY weather_condition
ORDER BY avg_delivery_time DESC;


-- ============================================================================
-- QUERY 08: TRAFFIC x WEATHER INTERACTION
-- Purpose: Identify combinations associated with longer delivery times.
-- Minimum group size of 10 matches the exploratory analysis run in the project.
-- ============================================================================
SELECT
    COALESCE(NULLIF(TRIM(Weather_conditions), ''), 'Unknown') AS weather_condition,
    COALESCE(NULLIF(TRIM(Road_traffic_density), ''), 'Unknown') AS traffic_condition,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_delivery_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM delivery_predictions), 2)
        AS order_percentage
FROM delivery_predictions
GROUP BY weather_condition, traffic_condition
HAVING COUNT(*) >= 10
ORDER BY avg_delivery_time DESC;


-- ============================================================================
-- QUERY 09: DELIVERY DISTANCE BANDS
-- Purpose: Compare delivery duration and model error across Haversine distances.
-- Missing distances are excluded, matching the executed 8,306-row analysis.
-- Bands: [0,5), [5,10), [10,15), and 15+ km.
-- ============================================================================
WITH distance_groups AS (
    SELECT
        CASE
            WHEN distance_km < 5 THEN '0-5 km'
            WHEN distance_km < 10 THEN '5-10 km'
            WHEN distance_km < 15 THEN '10-15 km'
            ELSE '15+ km'
        END AS distance_band,
        actual_minutes,
        predicted_minutes,
        absolute_error_minutes
    FROM delivery_predictions
    WHERE distance_km IS NOT NULL
)
SELECT
    distance_band,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_delivery_time,
    ROUND(AVG(predicted_minutes), 2) AS avg_predicted_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error
FROM distance_groups
GROUP BY distance_band
ORDER BY
    CASE distance_band
        WHEN '0-5 km' THEN 1
        WHEN '5-10 km' THEN 2
        WHEN '10-15 km' THEN 3
        ELSE 4
    END;


-- ============================================================================
-- QUERY 10: MULTIPLE-DELIVERY CATEGORY ANALYSIS
-- Purpose: Compare delivery duration and prediction error by recorded category.
-- Numeric category values are preserved as exported; labels are not reinterpreted.
-- ============================================================================
SELECT
    COALESCE(CAST(multiple_deliveries AS TEXT), 'Unknown') AS multiple_deliveries_category,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_delivery_time,
    ROUND(AVG(predicted_minutes), 2) AS avg_predicted_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM delivery_predictions), 2)
        AS order_percentage
FROM delivery_predictions
GROUP BY multiple_deliveries
ORDER BY
    CASE WHEN multiple_deliveries IS NULL THEN 999 ELSE multiple_deliveries END;


-- ============================================================================
-- QUERY 11: DETAILED COURIER-RATING DISTRIBUTION
-- Purpose: Inspect the distinct rating values and sample size before banding.
-- Small rating groups should not be over-interpreted.
-- ============================================================================
SELECT
    COALESCE(CAST(Delivery_person_Ratings AS TEXT), 'Unknown') AS courier_rating,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_delivery_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(AVG(error_minutes), 2) AS average_prediction_bias
FROM delivery_predictions
GROUP BY Delivery_person_Ratings
ORDER BY
    CASE WHEN Delivery_person_Ratings IS NULL THEN 0 ELSE 1 END,
    Delivery_person_Ratings;


-- ============================================================================
-- QUERY 12: COURIER-RATING SEGMENTATION
-- Purpose: Compare delivery performance across interpretable rating bands.
-- Groups: <3.5, 3.5-<4.0, 4.0-<4.5, 4.5-5.0, and Unknown.
-- ============================================================================
WITH courier_groups AS (
    SELECT
        CASE
            WHEN Delivery_person_Ratings IS NULL THEN 'Unknown'
            WHEN Delivery_person_Ratings < 3.5 THEN 'Below 3.5'
            WHEN Delivery_person_Ratings < 4.0 THEN '3.5-3.9'
            WHEN Delivery_person_Ratings < 4.5 THEN '4.0-4.4'
            ELSE '4.5-5.0'
        END AS rating_band,
        CASE
            WHEN Delivery_person_Ratings IS NULL THEN 5
            WHEN Delivery_person_Ratings < 3.5 THEN 1
            WHEN Delivery_person_Ratings < 4.0 THEN 2
            WHEN Delivery_person_Ratings < 4.5 THEN 3
            ELSE 4
        END AS sort_order,
        actual_minutes,
        predicted_minutes,
        absolute_error_minutes,
        error_minutes
    FROM delivery_predictions
)
SELECT
    rating_band,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_delivery_time,
    ROUND(AVG(predicted_minutes), 2) AS avg_predicted_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(AVG(error_minutes), 2) AS prediction_bias,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM delivery_predictions), 2)
        AS order_percentage
FROM courier_groups
GROUP BY rating_band, sort_order
ORDER BY sort_order;


-- ============================================================================
-- QUERY 13: CITY-CATEGORY PERFORMANCE
-- Purpose: Compare delivery duration and model error by source city category.
-- Categories are dataset labels, not individual named cities.
-- ============================================================================
SELECT
    COALESCE(NULLIF(TRIM(City), ''), 'Unknown') AS city_category,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_delivery_time,
    ROUND(AVG(predicted_minutes), 2) AS avg_predicted_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(AVG(error_minutes), 2) AS prediction_bias,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM delivery_predictions), 2)
        AS order_percentage
FROM delivery_predictions
GROUP BY city_category
ORDER BY avg_delivery_time DESC;


-- ============================================================================
-- QUERY 14: ORDER-CATEGORY PERFORMANCE
-- Purpose: Compare delivery duration and prediction error by order type.
-- ============================================================================
SELECT
    COALESCE(NULLIF(TRIM(Type_of_order), ''), 'Unknown') AS order_category,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_delivery_time,
    ROUND(AVG(predicted_minutes), 2) AS avg_predicted_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(AVG(error_minutes), 2) AS prediction_bias,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM delivery_predictions), 2)
        AS order_percentage
FROM delivery_predictions
GROUP BY order_category
ORDER BY avg_delivery_time DESC;


-- ============================================================================
-- QUERY 15: VEHICLE-TYPE PERFORMANCE
-- Purpose: Compare delivery duration and prediction error by vehicle category.
-- ============================================================================
SELECT
    COALESCE(NULLIF(TRIM(Type_of_vehicle), ''), 'Unknown') AS vehicle_category,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_delivery_time,
    ROUND(AVG(predicted_minutes), 2) AS avg_predicted_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(AVG(error_minutes), 2) AS prediction_bias,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM delivery_predictions), 2)
        AS order_percentage
FROM delivery_predictions
GROUP BY vehicle_category
ORDER BY avg_delivery_time DESC;


-- ============================================================================
-- QUERY 16: FESTIVAL-INDICATOR ANALYSIS
-- Purpose: Compare delivery duration and model error by the source Festival flag.
-- This is a source indicator, not a verified calendar/event dataset.
-- ============================================================================
SELECT
    COALESCE(NULLIF(TRIM(Festival), ''), 'Unknown') AS festival_condition,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_minutes), 2) AS avg_delivery_time,
    ROUND(AVG(predicted_minutes), 2) AS avg_predicted_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(AVG(error_minutes), 2) AS prediction_bias,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM delivery_predictions), 2)
        AS order_percentage
FROM delivery_predictions
GROUP BY festival_condition
ORDER BY avg_delivery_time DESC;


-- ============================================================================
-- QUERY 17: PREDICTION-ERROR SEGMENTATION
-- Purpose: Measure the share of predictions in absolute-error bands.
-- Non-overlapping bands: <=2, >2-5, >5-10, and >10 minutes.
-- ============================================================================
WITH error_groups AS (
    SELECT
        CASE
            WHEN absolute_error_minutes <= 2 THEN '0-2 minutes'
            WHEN absolute_error_minutes <= 5 THEN '>2-5 minutes'
            WHEN absolute_error_minutes <= 10 THEN '>5-10 minutes'
            ELSE 'Above 10 minutes'
        END AS error_band,
        CASE
            WHEN absolute_error_minutes <= 2 THEN 1
            WHEN absolute_error_minutes <= 5 THEN 2
            WHEN absolute_error_minutes <= 10 THEN 3
            ELSE 4
        END AS sort_order,
        actual_minutes,
        absolute_error_minutes
    FROM delivery_predictions
)
SELECT
    error_band,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM delivery_predictions), 2)
        AS order_percentage,
    ROUND(AVG(actual_minutes), 2) AS avg_actual_delivery_time,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error
FROM error_groups
GROUP BY error_band, sort_order
ORDER BY sort_order;


-- ============================================================================
-- QUERY 18: OVERPREDICTION VS UNDERPREDICTION
-- Purpose: Count prediction direction using a 0.001-minute near-exact tolerance.
-- Positive error = underprediction; negative error = overprediction.
-- ============================================================================
WITH prediction_groups AS (
    SELECT
        CASE
            WHEN error_minutes > 0.001 THEN 'Underprediction'
            WHEN error_minutes < -0.001 THEN 'Overprediction'
            ELSE 'Near-exact prediction'
        END AS prediction_direction,
        error_minutes,
        absolute_error_minutes,
        actual_minutes
    FROM delivery_predictions
)
SELECT
    prediction_direction,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM delivery_predictions), 2)
        AS order_percentage,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error,
    ROUND(AVG(error_minutes), 2) AS average_signed_error,
    ROUND(AVG(actual_minutes), 2) AS avg_actual_delivery_time
FROM prediction_groups
GROUP BY prediction_direction
ORDER BY
    CASE prediction_direction
        WHEN 'Underprediction' THEN 1
        WHEN 'Overprediction' THEN 2
        ELSE 3
    END;


-- ============================================================================
-- QUERY 19: PREDICTION DIRECTION BY TRAFFIC DENSITY
-- Purpose: Identify traffic categories with more underprediction or overprediction.
-- Uses the same 0.001-minute tolerance as Query 18.
-- ============================================================================
WITH prediction_groups AS (
    SELECT
        COALESCE(NULLIF(TRIM(Road_traffic_density), ''), 'Unknown') AS traffic_condition,
        CASE
            WHEN error_minutes > 0.001 THEN 'Underprediction'
            WHEN error_minutes < -0.001 THEN 'Overprediction'
            ELSE 'Near-exact'
        END AS prediction_direction,
        error_minutes,
        absolute_error_minutes
    FROM delivery_predictions
)
SELECT
    traffic_condition,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN prediction_direction = 'Underprediction' THEN 1 ELSE 0 END)
        AS underpredicted_orders,
    SUM(CASE WHEN prediction_direction = 'Overprediction' THEN 1 ELSE 0 END)
        AS overpredicted_orders,
    ROUND(
        100.0 * SUM(CASE WHEN prediction_direction = 'Underprediction' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS underprediction_percentage,
    ROUND(AVG(error_minutes), 2) AS average_signed_error,
    ROUND(AVG(absolute_error_minutes), 2) AS mean_absolute_error
FROM prediction_groups
GROUP BY traffic_condition
ORDER BY underprediction_percentage DESC;


-- ============================================================================
-- QUERY 20: SEVERE PREDICTION ERRORS BY WEATHER AND TRAFFIC
-- Purpose: Find operating-condition groups with high rates of errors >10 minutes.
-- Minimum group size of 30 matches the executed investigation.
-- ============================================================================
SELECT
    COALESCE(NULLIF(TRIM(Weather_conditions), ''), 'Unknown') AS weather_condition,
    COALESCE(NULLIF(TRIM(Road_traffic_density), ''), 'Unknown') AS traffic_condition,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN absolute_error_minutes > 10 THEN 1 ELSE 0 END)
        AS severe_error_orders,
    ROUND(
        100.0 * SUM(CASE WHEN absolute_error_minutes > 10 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS severe_error_percentage,
    ROUND(
        AVG(CASE WHEN absolute_error_minutes > 10 THEN absolute_error_minutes END),
        2
    ) AS avg_severe_error
FROM delivery_predictions
GROUP BY weather_condition, traffic_condition
HAVING COUNT(*) >= 30
ORDER BY severe_error_percentage DESC, total_orders DESC;


-- ============================================================================
-- QUERY 21: ORDERS ABOVE A PROJECT-DEFINED 30-MINUTE THRESHOLD (OPTIONAL)
-- Purpose: Quantify the share of test orders with actual time >30 minutes.
-- This is an exploratory threshold, NOT a published delivery SLA.
-- Execute and review this query before adding its result to the report.
-- ============================================================================
SELECT
    COUNT(*) AS test_orders,
    SUM(CASE WHEN actual_minutes > 30 THEN 1 ELSE 0 END) AS orders_over_30_minutes,
    ROUND(
        100.0 * SUM(CASE WHEN actual_minutes > 30 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS share_over_30_minutes_pct
FROM delivery_predictions;
