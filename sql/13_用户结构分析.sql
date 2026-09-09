-- 分析目的：比较首次观察与已观察老用户的规模、活跃度、付费及收入贡献。
-- 最终口径：2019-10 受观察窗口起点影响；行为漏斗 has_purchase 包含全部购买，付费率使用 has_paid_purchase。
USE user_behavior_analysis;

SELECT
    event_month,

    COUNT(*) AS mau,

    SUM(CASE
            WHEN user_type = 'new' THEN 1
            ELSE 0
        END) AS new_users,

    SUM(CASE
            WHEN user_type = 'old' THEN 1
            ELSE 0
        END) AS old_users,

    ROUND(
        SUM(CASE WHEN user_type = 'new' THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS new_user_share,

    ROUND(
        SUM(CASE WHEN user_type = 'old' THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS old_user_share

FROM user_monthly_profile
GROUP BY event_month
ORDER BY event_month;

SELECT
    event_month,
    user_type,

    COUNT(*) AS users,

    SUM(event_cnt) AS total_events,

    ROUND(AVG(event_cnt), 2) AS events_per_user,

    ROUND(AVG(active_days), 2) AS active_days_per_user

FROM user_monthly_profile
GROUP BY event_month, user_type
ORDER BY event_month, user_type;

SELECT
    event_month,
    user_type,

    COUNT(*) AS active_users,

    SUM(has_paid_purchase) AS paid_users,

    ROUND(
        SUM(has_paid_purchase) / COUNT(*) * 100,
        2
    ) AS paid_purchase_rate

FROM user_monthly_profile
GROUP BY event_month, user_type
ORDER BY event_month, user_type;

SELECT
    event_month,
    user_type,

    COUNT(*) AS active_users,

    SUM(has_paid_purchase) AS paid_users,

    ROUND(SUM(revenue), 2) AS revenue

FROM user_monthly_profile
GROUP BY event_month, user_type
ORDER BY event_month, user_type;

WITH revenue_summary AS (
    SELECT
        event_month,
        user_type,
        SUM(revenue) AS revenue
    FROM user_monthly_profile
    GROUP BY event_month, user_type
)

SELECT
    event_month,
    user_type,

    ROUND(revenue, 2) AS revenue,

    ROUND(
        revenue
        / SUM(revenue) OVER(PARTITION BY event_month)
        * 100,
        2
    ) AS revenue_share

FROM revenue_summary
ORDER BY event_month, user_type;

SELECT
    event_month,
    user_type,

    /* 浏览用户 */
    SUM(has_view) AS view_users,

    /* 浏览且加购用户 */
    SUM(
        CASE
            WHEN has_view = 1
             AND has_cart = 1
            THEN 1 ELSE 0
        END
    ) AS view_cart_users,

    /* 浏览、加购和购买用户 */
    SUM(
        CASE
            WHEN has_view = 1
             AND has_cart = 1
             AND has_purchase = 1
            THEN 1 ELSE 0
        END
    ) AS complete_users,

    /* 浏览到加购 */
    ROUND(
        SUM(
            CASE
                WHEN has_view = 1 AND has_cart = 1
                THEN 1 ELSE 0
            END
        )
        / NULLIF(SUM(has_view), 0)
        * 100,
        2
    ) AS view_to_cart_rate,

    /* 加购到购买 */
    ROUND(
        SUM(
            CASE
                WHEN has_view = 1
                 AND has_cart = 1
                 AND has_purchase = 1
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN has_view = 1
                     AND has_cart = 1
                    THEN 1 ELSE 0
                END
            ),
            0
        )
        * 100,
        2
    ) AS cart_to_purchase_rate,

    /* 整体转化率 */
    ROUND(
        SUM(
            CASE
                WHEN has_view = 1
                 AND has_cart = 1
                 AND has_purchase = 1
                THEN 1 ELSE 0
            END
        )
        / NULLIF(SUM(has_view), 0)
        * 100,
        2
    ) AS overall_rate

FROM user_monthly_profile
WHERE event_month = '2019-11'
GROUP BY event_month, user_type
ORDER BY user_type;
