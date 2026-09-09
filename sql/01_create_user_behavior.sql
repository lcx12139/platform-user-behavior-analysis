-- 分析目的：建立行为明细事实表；保留缺失会话和非正价格行为。
-- 不自动删除已有数据或汇总表；已有库请仅执行结果查询部分。
USE user_behavior_analysis;

CREATE TABLE IF NOT EXISTS user_behavior (
    event_time DATETIME,
    event_type VARCHAR(30),

    product_id BIGINT,
    category_id VARCHAR(30),

    category_code VARCHAR(255),
    brand VARCHAR(100),

    price DECIMAL(10,2),

    user_id BIGINT,
    user_session VARCHAR(50),

    event_date DATE,
    event_month VARCHAR(7),
    event_hour TINYINT,
    event_weekday TINYINT,
    is_weekend VARCHAR(5)
);
