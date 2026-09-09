-- 分析目的：按位置导入五个月 CSV；支持旧字段名，换行必须为 CRLF。
-- 仅用于空表；每月导入后立即执行 SHOW WARNINGS，禁止对已有数据重复导入。
-- 会话空字符串沿用历史导入行为；请按指标口径文档检查 NULL 与空字符串。
-- 不自动删除已有数据或汇总表；已有库请仅执行结果查询部分。
USE user_behavior_analysis;

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
