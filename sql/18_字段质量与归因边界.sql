-- 分析目的：核对2019-11品类字段缺失，决定是否支持品类归因。
-- 最终口径：NULL、空字符串、Unknown 均视为 category_code 缺失；98.32%为用户确认结果，本次不重跑。
USE user_behavior_analysis;

SELECT
    COUNT(*) AS total_events,

    SUM(
        CASE
            WHEN category_code IS NULL
              OR category_code = ''
              OR category_code = 'Unknown'
            THEN 1 ELSE 0
        END
    ) AS missing_category_events,

    ROUND(
        SUM(
            CASE
                WHEN category_code IS NULL
                  OR category_code = ''
                  OR category_code = 'Unknown'
                THEN 1 ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS missing_category_rate

FROM user_behavior
WHERE event_month = '2019-11';
