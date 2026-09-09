-- 分析目的：建立用户×月份画像，供用户结构、留存、漏斗和看板复用。
-- 最终口径：new 为首次观察月份，old 为后续活跃月份；收入及付费标记仅用正价格购买。
USE user_behavior_analysis;

-- 已有 user_monthly_profile 时请使用现有汇总或在隔离库重建；不自动删除。

CREATE TABLE user_monthly_profile AS
WITH monthly_behavior AS (
    SELECT
        user_id,
        event_month,

        /* 活跃度 */
        COUNT(*) AS event_cnt,
        COUNT(DISTINCT event_date) AS active_days,

        /* 行为标记 */
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS has_view,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
        MAX(CASE WHEN event_type = 'remove_from_cart' THEN 1 ELSE 0 END) AS has_remove,

        /* 行为购买标记：保留全部价格 */
        MAX(CASE
                WHEN event_type = 'purchase'
                THEN 1 ELSE 0
            END) AS has_purchase,

        /* 正价格购买标记 */
        MAX(CASE
                WHEN event_type = 'purchase'
                     AND price > 0
                THEN 1 ELSE 0
            END) AS has_paid_purchase,

        /* Revenue口径：只计算正价格purchase */
        SUM(CASE
                WHEN event_type = 'purchase'
                     AND price > 0
                THEN price
                ELSE 0
            END) AS revenue

    FROM user_behavior
    GROUP BY user_id, event_month
),

first_month AS (
    SELECT
        user_id,
        MIN(event_month) AS first_active_month
    FROM monthly_behavior
    GROUP BY user_id
)

SELECT
    m.user_id,
    m.event_month,
    f.first_active_month,

    CASE
        WHEN m.event_month = f.first_active_month THEN 'new'
        ELSE 'old'
    END AS user_type,

    m.event_cnt,
    m.active_days,

    m.has_view,
    m.has_cart,
    m.has_remove,
    m.has_purchase,
    m.has_paid_purchase,
    m.revenue

FROM monthly_behavior m
JOIN first_month f
    ON m.user_id = f.user_id;
    ALTER TABLE user_monthly_profile
ADD INDEX idx_month_type (event_month, user_type),
ADD INDEX idx_user_month (user_id, event_month);
SELECT *
FROM user_monthly_profile
LIMIT 20;
