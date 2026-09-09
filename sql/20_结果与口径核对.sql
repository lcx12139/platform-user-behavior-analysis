-- 分析目的：只读核对最终用户、金额、会话与看板口径；不删除或重建任何对象。
-- 最终口径：任意行为用户总数、正价格金额、购买会话近似频次；大表查询可能耗时。
USE user_behavior_analysis;
SELECT COUNT(*) AS clean_events, COUNT(DISTINCT user_id) AS all_behavior_users FROM user_behavior;
SELECT COUNT(DISTINCT user_id) AS profile_users FROM user_monthly_profile;
SELECT COUNT(*) AS three_event_users FROM user_first_event;
-- 检查旧三类行为汇总未覆盖的人数，不预设其事件组合。
SELECT COUNT(DISTINCT u.user_id) AS users_not_in_first_event
FROM user_monthly_profile u LEFT JOIN user_first_event f ON u.user_id=f.user_id
WHERE f.user_id IS NULL;
SELECT COUNT(*) AS positive_purchase_events,
 COUNT(DISTINCT user_id) AS positive_purchase_users,
 SUM(user_session IS NULL) AS null_sessions,
 SUM(user_session = '') AS blank_sessions,
 SUM(price) AS positive_purchase_revenue
FROM user_behavior WHERE event_type = 'purchase' AND price > 0;
SELECT COUNT(*) AS paying_users, MIN(frequency) AS min_frequency,
 ROUND(AVG(recency_days),2) AS avg_recency,
 ROUND(AVG(frequency),2) AS avg_frequency,
 ROUND(AVG(monetary),2) AS avg_monetary
FROM user_rfm;
SELECT * FROM bi_overall_kpi;
SELECT * FROM bi_conversion_kpi;
SELECT * FROM bi_cohort_retention ORDER BY cohort_month, month_number;
SELECT * FROM bi_rfm_segment ORDER BY revenue DESC;
SELECT * FROM bi_conversion_decomposition;
