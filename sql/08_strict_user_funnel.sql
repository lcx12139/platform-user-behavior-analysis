-- User-level STRICT first-event approximation; strictly increasing first timestamps.
-- MySQL 8.0+. Run in numeric order on a fresh database; do not blindly rerun loads.
USE user_behavior_analysis;

CREATE TABLE user_first_event (
    user_id BIGINT PRIMARY KEY,
    first_view_time DATETIME,
    first_cart_time DATETIME,
    first_purchase_time DATETIME
);
INSERT INTO user_first_event (user_id, first_view_time)
SELECT
    user_id,
    MIN(event_time)
FROM user_behavior
WHERE event_type = 'view'
GROUP BY user_id;
INSERT INTO user_first_event (user_id, first_cart_time)
SELECT
    user_id,
    MIN(event_time)
FROM user_behavior
WHERE event_type = 'cart'
GROUP BY user_id
ON DUPLICATE KEY UPDATE
    first_cart_time = VALUES(first_cart_time);
INSERT INTO user_first_event (
    user_id,
    first_purchase_time
)
SELECT
    user_id,
    MIN(event_time)
FROM user_behavior
WHERE event_type = 'purchase'
GROUP BY user_id
ON DUPLICATE KEY UPDATE
    first_purchase_time = VALUES(first_purchase_time);
WITH strict_funnel AS (SELECT
        SUM(CASE  WHEN first_view_time IS NOT NULL THEN 1 ELSE 0 END) AS view_users,
        SUM(CASE  WHEN first_view_time IS NOT NULL AND first_cart_time IS NOT NULL
                 AND first_view_time < first_cart_time THEN 1 ELSE 0 END) AS view_cart_users,
        SUM(CASE WHEN first_view_time IS NOT NULL AND first_cart_time IS NOT NULL AND first_purchase_time IS NOT NULL
                 AND first_view_time < first_cart_time  AND first_cart_time < first_purchase_time
                THEN 1 ELSE 0 END) AS view_cart_purchase_users
    FROM user_first_event)
SELECT
    view_users,view_cart_users,view_cart_purchase_users,
    ROUND(view_cart_users / NULLIF(view_users, 0) * 100,2) AS view_cart_rate,
    ROUND(view_cart_purchase_users / NULLIF(view_cart_users, 0) * 100,2) AS cart_purchase_rate,
    ROUND(view_cart_purchase_users / NULLIF(view_users, 0) * 100,2) AS overall_rate
FROM strict_funnel;
