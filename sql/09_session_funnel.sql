-- 分析目的：Session（访问会话）级首次时间严格近似漏斗；沿用会话标识单键及非 NULL 过滤。
-- 不自动删除已有数据或汇总表；已有库请仅执行结果查询部分。
USE user_behavior_analysis;

CREATE TABLE session_first_event (
    user_session VARCHAR(50) PRIMARY KEY,
    user_id BIGINT,
    first_view_time DATETIME,
    first_cart_time DATETIME,
    first_purchase_time DATETIME
);
INSERT INTO session_first_event (
    user_session,
    user_id,
    first_view_time
)
SELECT
    user_session,
    MIN(user_id) AS user_id,
    MIN(event_time) AS first_view_time
FROM user_behavior
WHERE event_type = 'view'
  AND user_session IS NOT NULL
GROUP BY user_session;
INSERT INTO session_first_event (
    user_session,
    user_id,
    first_cart_time
)
SELECT
    user_session,
    MIN(user_id) AS user_id,
    MIN(event_time) AS first_cart_time
FROM user_behavior
WHERE event_type = 'cart'
  AND user_session IS NOT NULL
GROUP BY user_session
ON DUPLICATE KEY UPDATE
    first_cart_time = VALUES(first_cart_time);

INSERT INTO session_first_event (
    user_session,
    user_id,
    first_purchase_time
)
SELECT
    user_session,
    MIN(user_id) AS user_id,
    MIN(event_time) AS first_purchase_time
FROM user_behavior
WHERE event_type = 'purchase'
  AND user_session IS NOT NULL
GROUP BY user_session
ON DUPLICATE KEY UPDATE
    first_purchase_time = VALUES(first_purchase_time);

ALTER TABLE session_first_event
ADD COLUMN first_remove_time DATETIME;
INSERT INTO session_first_event (
    user_session,
    user_id,
    first_remove_time
)
SELECT
    user_session,
    MIN(user_id) AS user_id,
    MIN(event_time) AS first_remove_time
FROM user_behavior
WHERE event_type = 'remove_from_cart'
  AND user_session IS NOT NULL
GROUP BY user_session
ON DUPLICATE KEY UPDATE
    first_remove_time = VALUES(first_remove_time);
WITH session_funnel AS ( SELECT
        SUM(CASE WHEN first_view_time IS NOT NULL THEN 1 ELSE 0 END) AS view_sessions,
        SUM(CASE WHEN first_view_time IS NOT NULL
                 AND first_cart_time IS NOT NULL
                 AND first_view_time < first_cart_time
                THEN 1 ELSE 0  END) AS view_cart_sessions,
        SUM(CASE WHEN first_view_time IS NOT NULL
                 AND first_cart_time IS NOT NULL
				 AND first_purchase_time IS NOT NULL
                 AND first_view_time < first_cart_time
                 AND first_cart_time < first_purchase_time
                THEN 1 ELSE 0 END) AS completed_sessions FROM session_first_event)
SELECT  view_sessions, view_cart_sessions,completed_sessions,
    ROUND(view_cart_sessions / NULLIF(view_sessions, 0) * 100,2 ) AS view_cart_rate,
    ROUND(completed_sessions / NULLIF(view_cart_sessions, 0) * 100,2) AS cart_purchase_rate,
    ROUND(completed_sessions / NULLIF(view_sessions, 0) * 100,2) AS overall_rate FROM session_funnel;
