-- 分析目的：输出月度 Cohort（同期群）留存长表和矩阵。
-- 最终口径：首个观察活跃月份为同期群；当月任何行为均算活跃；M0 为 100%，观察不到的后续月份不是零留存。
USE user_behavior_analysis;

WITH cohort_data AS (
    SELECT
        user_id,
        first_active_month AS cohort_month,
        event_month,

        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(
                CONCAT(first_active_month, '-01'),
                '%Y-%m-%d'
            ),
            STR_TO_DATE(
                CONCAT(event_month, '-01'),
                '%Y-%m-%d'
            )
        ) AS month_number

    FROM user_monthly_profile
),

cohort_retention AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT user_id) AS active_users
    FROM cohort_data
    GROUP BY cohort_month, month_number
),

cohort_size AS (
    SELECT
        cohort_month,
        active_users AS cohort_users
    FROM cohort_retention
    WHERE month_number = 0
)

SELECT
    r.cohort_month,
    r.month_number,
    s.cohort_users,
    r.active_users,

    ROUND(
        r.active_users / s.cohort_users * 100,
        2
    ) AS retention_rate

FROM cohort_retention r
JOIN cohort_size s
    ON r.cohort_month = s.cohort_month

ORDER BY
    r.cohort_month,
    r.month_number;

    WITH cohort_data AS (
    SELECT
        user_id,
        first_active_month AS cohort_month,
        event_month,

        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(first_active_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(event_month, '-01'), '%Y-%m-%d')
        ) AS month_number

    FROM user_monthly_profile
),

cohort_retention AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT user_id) AS active_users
    FROM cohort_data
    GROUP BY cohort_month, month_number
),

cohort_size AS (
    SELECT
        cohort_month,
        active_users AS cohort_users
    FROM cohort_retention
    WHERE month_number = 0
),

retention AS (
    SELECT
        r.cohort_month,
        r.month_number,

        ROUND(
            r.active_users / s.cohort_users * 100,
            2
        ) AS retention_rate

    FROM cohort_retention r
    JOIN cohort_size s
      ON r.cohort_month = s.cohort_month
)

SELECT
    cohort_month,

    MAX(CASE
        WHEN month_number = 0
        THEN retention_rate
    END) AS M0,

    MAX(CASE
        WHEN month_number = 1
        THEN retention_rate
    END) AS M1,

    MAX(CASE
        WHEN month_number = 2
        THEN retention_rate
    END) AS M2,

    MAX(CASE
        WHEN month_number = 3
        THEN retention_rate
    END) AS M3,

    MAX(CASE
        WHEN month_number = 4
        THEN retention_rate
    END) AS M4

FROM retention
GROUP BY cohort_month
ORDER BY cohort_month;
