-- Daily/monthly activity and daily Purchase Revenue, ARPU, ARPPU. No order_id or quantity.
-- MySQL 8.0+. Run in numeric order on a fresh database; do not blindly rerun loads.
USE user_behavior_analysis;

SELECT COUNT(DISTINCT user_id) AS observed_users FROM user_behavior;
SELECT event_month, COUNT(DISTINCT user_id) AS mau
FROM user_behavior GROUP BY event_month ORDER BY event_month;
SELECT event_date, COUNT(DISTINCT user_id) AS dau
FROM user_behavior GROUP BY event_date ORDER BY event_date;
SELECT event_month, event_type, COUNT(*) AS event_count
FROM user_behavior GROUP BY event_month, event_type ORDER BY event_month, event_type;
-- Behavior-based purchasing users include all purchase records.
SELECT event_date, COUNT(DISTINCT user_id) AS purchasing_users
FROM user_behavior WHERE event_type = 'purchase' GROUP BY event_date ORDER BY event_date;
-- Amount metrics: positive-price purchase events only. ARPPU denominator confirmed by owner.
WITH daily AS (
    SELECT event_date, COUNT(DISTINCT user_id) AS active_users,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' AND price > 0 THEN user_id END) AS positive_price_buyers,
        SUM(CASE WHEN event_type = 'purchase' AND price > 0 THEN price ELSE 0 END) AS purchase_revenue
    FROM user_behavior GROUP BY event_date
)
SELECT event_date, active_users, positive_price_buyers, purchase_revenue,
    purchase_revenue / NULLIF(active_users, 0) AS arpu,
    purchase_revenue / NULLIF(positive_price_buyers, 0) AS arppu
FROM daily ORDER BY event_date;
