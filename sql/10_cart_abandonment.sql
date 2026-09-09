-- 分析目的：全部加购会话的放弃分析，不要求浏览；首次购买必须晚于首次加购才记为转化。
-- 不自动删除已有数据或汇总表；已有库请仅执行结果查询部分。
USE user_behavior_analysis;

WITH cart_summary AS (
    SELECT
        COUNT(
            CASE
                WHEN first_cart_time IS NOT NULL
                THEN 1
            END
        ) AS cart_sessions,

        COUNT(
            CASE
                WHEN first_cart_time IS NOT NULL
                 AND (
                     first_purchase_time IS NULL
                     OR first_purchase_time <= first_cart_time
                 )
                THEN 1
            END
        ) AS abandoned_sessions

    FROM session_first_event
)

SELECT
    cart_sessions,
    abandoned_sessions,

    cart_sessions - abandoned_sessions AS converted_sessions,

    ROUND(
        abandoned_sessions / NULLIF(cart_sessions, 0) * 100,
        2
    ) AS abandonment_rate,

    ROUND(
        (cart_sessions - abandoned_sessions)
        / NULLIF(cart_sessions, 0) * 100,
        2
    ) AS cart_conversion_rate

FROM cart_summary;
