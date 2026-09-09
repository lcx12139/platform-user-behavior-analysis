-- 分析目的：月度用户级宽口径漏斗：同月内行为共现；用户可跨月重复出现。
-- 不自动删除已有数据或汇总表；已有库请仅执行结果查询部分。
USE user_behavior_analysis;

CREATE TABLE monthly_funnel_summary (
    event_month VARCHAR(7) NOT NULL,
    user_id BIGINT NOT NULL,

    has_view TINYINT NOT NULL DEFAULT 0,
    has_cart TINYINT NOT NULL DEFAULT 0,
    has_purchase TINYINT NOT NULL DEFAULT 0,

    PRIMARY KEY (event_month, user_id)
);
INSERT INTO monthly_funnel_summary
    (event_month, user_id, has_view)

SELECT DISTINCT
    event_month,
    user_id,
    1
FROM user_behavior
WHERE event_type = 'view';
INSERT INTO monthly_funnel_summary
    (event_month, user_id, has_cart)

SELECT DISTINCT
    event_month,
    user_id,
    1
FROM user_behavior
WHERE event_type = 'cart'

ON DUPLICATE KEY UPDATE
    has_cart = 1;
    INSERT INTO monthly_funnel_summary
    (event_month, user_id, has_purchase)

SELECT DISTINCT
    event_month,
    user_id,
    1
FROM user_behavior
WHERE event_type = 'purchase'

ON DUPLICATE KEY UPDATE
    has_purchase = 1;



WITH t AS ( SELECT event_month,
	SUM(has_view) AS view_users,
    SUM(CASE WHEN has_view = 1 AND has_cart = 1 THEN 1 ELSE 0 END) AS view_cart_users,
    SUM(CASE WHEN has_view = 1 AND has_cart = 1 AND has_purchase = 1 THEN 1 ELSE 0 END ) AS view_cart_purchase_users
    FROM monthly_funnel_summary
    GROUP BY event_month
)

SELECT event_month,view_users,view_cart_users,view_cart_purchase_users,
    ROUND(view_cart_users/ NULLIF(view_users, 0)*100 ,2) view_cart_rate,
    ROUND(view_cart_purchase_users/ NULLIF(view_cart_users, 0)*100,2) cart_purchase_rate,
    ROUND(view_cart_purchase_users/ NULLIF(view_users, 0)*100,2) overall_rate
FROM t
ORDER BY event_month;
