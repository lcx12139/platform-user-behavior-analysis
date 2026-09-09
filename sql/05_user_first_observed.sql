-- 分析目的：计算观察期首次活跃用户；不代表真实注册或获客时间。
-- 不自动删除已有数据或汇总表；已有库请仅执行结果查询部分。
USE user_behavior_analysis;

WITH first_observed AS (
    SELECT user_id, MIN(event_date) AS first_observed_date
    FROM user_behavior GROUP BY user_id
)
SELECT DATE_FORMAT(first_observed_date, '%Y-%m') AS first_observed_month,
    COUNT(*) AS first_observed_users
FROM first_observed GROUP BY first_observed_month ORDER BY first_observed_month;
