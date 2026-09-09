-- Import five CSVs by POSITION, supporting legacy and standardized headers. CRLF required.
-- Existing empty-session import behavior is preserved; see methodology before session analysis.
-- Requires client/server local_infile enabled. Inspect SHOW WARNINGS after EACH load.
-- Never run twice against a populated fact table: duplicate loads are not prevented.
-- MySQL 8.0+. Run in numeric order on a fresh database; do not blindly rerun loads.
USE user_behavior_analysis;

-- =========================
-- 2019-Dec
-- =========================
LOAD DATA LOCAL INFILE
'D:/data_analysis/data/cleaned/2019-Dec-cleaned.csv'
INTO TABLE user_behavior_analysis.user_behavior
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session,
    event_date,
    event_month,
    event_hour,
    event_weekday,
    is_weekend
);

-- =========================
-- 2019-Oct
-- =========================

LOAD DATA LOCAL INFILE
'D:/data_analysis/data/cleaned/2019-Oct-cleaned.csv'
INTO TABLE user_behavior
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session,
    event_date,
    event_month,
    event_hour,
    event_weekday,
    is_weekend
);
-- =========================
-- 2019-Nov
-- =========================

LOAD DATA LOCAL INFILE
'D:/data_analysis/data/cleaned/2019-Nov-cleaned.csv'
INTO TABLE user_behavior
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session,
    event_date,
    event_month,
    event_hour,
    event_weekday,
    is_weekend
);
-- =========================
-- 2020-Jan
-- =========================

LOAD DATA LOCAL INFILE
'D:/data_analysis/data/cleaned/2020-Jan-cleaned.csv'
INTO TABLE user_behavior
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session,
    event_date,
    event_month,
    event_hour,
    event_weekday,
    is_weekend
);
-- =========================
-- 2020-Feb
-- =========================

LOAD DATA LOCAL INFILE
'D:/data_analysis/data/cleaned/2020-Feb-cleaned.csv'
INTO TABLE user_behavior
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session,
    event_date,
    event_month,
    event_hour,
    event_weekday,
    is_weekend
);
