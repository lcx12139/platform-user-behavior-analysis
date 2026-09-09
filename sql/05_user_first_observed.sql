-- First observed within this dataset; NOT registration or acquisition date.
-- MySQL 8.0+. Run in numeric order on a fresh database; do not blindly rerun loads.
USE user_behavior_analysis;

WITH first_observed AS (
    SELECT user_id, MIN(event_date) AS first_observed_date
    FROM user_behavior GROUP BY user_id
)
SELECT DATE_FORMAT(first_observed_date, '%Y-%m') AS first_observed_month,
    COUNT(*) AS first_observed_users
FROM first_observed GROUP BY first_observed_month ORDER BY first_observed_month;
