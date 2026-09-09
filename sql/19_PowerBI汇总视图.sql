-- 分析目的：为四页 Power BI 看板提供汇总视图。
-- 最终口径：总用户最终来自覆盖全部行为的 user_monthly_profile 去重，不再从三类行为 user_first_event 计数；所有比例字段为0—100数值。
USE user_behavior_analysis;

CREATE OR REPLACE VIEW bi_monthly_kpi AS

SELECT
    event_month,

    /* 月活跃用户 */
    COUNT(*) AS mau,

    /* 观察期首次活跃用户 */
    SUM(
        CASE
            WHEN user_type = 'new'
            THEN 1 ELSE 0
        END
    ) AS new_users,

    /* 已观察老用户 */
    SUM(
        CASE
            WHEN user_type = 'old'
            THEN 1 ELSE 0
        END
    ) AS old_users,

    /* 正价格付费用户 */
    SUM(has_paid_purchase) AS paid_users,

    /* 正价格购买收入 */
    ROUND(SUM(revenue), 2) AS revenue,

    /* 正价格购买率 */
    ROUND(
        SUM(has_paid_purchase)
        / COUNT(*) * 100,
        2
    ) AS paid_purchase_rate,

    /* 每活跃用户平均收入 */
    ROUND(
        SUM(revenue)
        / COUNT(*),
        2
    ) AS arpu,

    /* 每正价格购买用户平均收入 */
    ROUND(
        SUM(revenue)
        / NULLIF(SUM(has_paid_purchase), 0),
        2
    ) AS arppu,

    /* 人均行为次数 */
    ROUND(
        AVG(event_cnt),
        2
    ) AS events_per_user,

    /* 人均活跃天数 */
    ROUND(
        AVG(active_days),
        2
    ) AS active_days_per_user

FROM user_monthly_profile

GROUP BY event_month;
SELECT *
FROM bi_monthly_kpi
ORDER BY event_month;


CREATE OR REPLACE VIEW bi_user_structure AS

SELECT
    event_month,
    user_type,

    COUNT(*) AS users,

    ROUND(
        COUNT(*)
        / SUM(COUNT(*)) OVER(PARTITION BY event_month)
        * 100,
        2
    ) AS user_share,

    ROUND(
        AVG(event_cnt),
        2
    ) AS events_per_user,

    ROUND(
        AVG(active_days),
        2
    ) AS active_days_per_user,

    SUM(has_paid_purchase) AS paid_users,

    ROUND(
        SUM(has_paid_purchase)
        / COUNT(*) * 100,
        2
    ) AS paid_purchase_rate,

    ROUND(
        SUM(revenue),
        2
    ) AS revenue,

    ROUND(
        SUM(revenue)
        /
        SUM(SUM(revenue)) OVER(PARTITION BY event_month)
        * 100,
        2
    ) AS revenue_share,

    ROUND(
        SUM(revenue) / COUNT(*),
        2
    ) AS arpu,

    ROUND(
        SUM(revenue)
        / NULLIF(SUM(has_paid_purchase), 0),
        2
    ) AS arppu

FROM user_monthly_profile

GROUP BY
    event_month,
    user_type;
SELECT *
FROM bi_user_structure
ORDER BY event_month, user_type;

CREATE OR REPLACE VIEW bi_cohort_retention AS

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

    GROUP BY
        cohort_month,
        month_number
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
        r.active_users
        / s.cohort_users
        * 100,
        2
    ) AS retention_rate

FROM cohort_retention r

JOIN cohort_size s
  ON r.cohort_month = s.cohort_month;
  SELECT *
FROM bi_cohort_retention
ORDER BY cohort_month, month_number;

CREATE OR REPLACE VIEW bi_rfm_segment AS

SELECT
    user_segment,

    COUNT(*) AS users,

    ROUND(
        COUNT(*)
        / SUM(COUNT(*)) OVER()
        * 100,
        2
    ) AS user_share,

    ROUND(
        SUM(monetary),
        2
    ) AS revenue,

    ROUND(
        SUM(monetary)
        / SUM(SUM(monetary)) OVER()
        * 100,
        2
    ) AS revenue_share,

    ROUND(
        AVG(monetary),
        2
    ) AS avg_monetary,

    ROUND(
        AVG(frequency),
        2
    ) AS avg_frequency,

    ROUND(
        AVG(recency_days),
        2
    ) AS avg_recency

FROM user_value_segment

GROUP BY user_segment;
SELECT *
FROM bi_rfm_segment
ORDER BY revenue DESC;

CREATE OR REPLACE VIEW bi_monthly_funnel AS

SELECT
    event_month,

    SUM(has_view) AS view_users,

    SUM(
        CASE
            WHEN has_view = 1
             AND has_cart = 1
            THEN 1 ELSE 0
        END
    ) AS view_cart_users,

    SUM(
        CASE
            WHEN has_view = 1
             AND has_cart = 1
             AND has_purchase = 1
            THEN 1 ELSE 0
        END
    ) AS complete_users,

    ROUND(
        SUM(
            CASE
                WHEN has_view = 1
                 AND has_cart = 1
                THEN 1 ELSE 0
            END
        )
        / SUM(has_view)
        * 100,
        2
    ) AS view_to_cart_rate,

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

    ROUND(
        SUM(
            CASE
                WHEN has_view = 1
                 AND has_cart = 1
                 AND has_purchase = 1
                THEN 1 ELSE 0
            END
        )
        / SUM(has_view)
        * 100,
        2
    ) AS overall_rate

FROM user_monthly_profile

GROUP BY event_month;

CREATE OR REPLACE VIEW bi_overall_kpi AS

WITH total_user AS (
    SELECT
        COUNT(DISTINCT user_id) AS total_users
    FROM user_monthly_profile
),

paying_user AS (
    SELECT
        COUNT(*) AS paid_users,
        SUM(monetary) AS revenue
    FROM user_rfm
)

SELECT
    t.total_users,
    p.paid_users,

    ROUND(p.revenue, 2) AS revenue,

    ROUND(
        p.paid_users / t.total_users * 100,
        2
    ) AS paid_user_rate,

    ROUND(
        p.revenue / t.total_users,
        2
    ) AS arpu,

    ROUND(
        p.revenue / p.paid_users,
        2
    ) AS arppu

FROM total_user t
CROSS JOIN paying_user p;
CREATE OR REPLACE VIEW bi_session_funnel AS

WITH funnel AS (
    SELECT
        SUM(
            CASE
                WHEN first_view_time IS NOT NULL
                THEN 1 ELSE 0
            END
        ) AS view_sessions,

        SUM(
            CASE
                WHEN first_view_time IS NOT NULL
                 AND first_cart_time IS NOT NULL
                 AND first_view_time < first_cart_time
                THEN 1 ELSE 0
            END
        ) AS view_cart_sessions,

        SUM(
            CASE
                WHEN first_view_time IS NOT NULL
                 AND first_cart_time IS NOT NULL
                 AND first_purchase_time IS NOT NULL
                 AND first_view_time < first_cart_time
                 AND first_cart_time < first_purchase_time
                THEN 1 ELSE 0
            END
        ) AS completed_sessions

    FROM session_first_event
)

SELECT
    1 AS stage_order,
    'View' AS stage,
    view_sessions AS sessions
FROM funnel

UNION ALL

SELECT
    2,
    'Cart',
    view_cart_sessions
FROM funnel

UNION ALL

SELECT
    3,
    'Purchase',
    completed_sessions
FROM funnel;
CREATE OR REPLACE VIEW bi_conversion_kpi AS

WITH x AS (
    SELECT
        SUM(
            CASE
                WHEN first_view_time IS NOT NULL
                THEN 1 ELSE 0
            END
        ) AS view_sessions,

        SUM(
            CASE
                WHEN first_view_time < first_cart_time
                THEN 1 ELSE 0
            END
        ) AS view_cart_sessions,

        SUM(
            CASE
                WHEN first_view_time < first_cart_time
                 AND first_cart_time < first_purchase_time
                THEN 1 ELSE 0
            END
        ) AS completed_sessions,

        SUM(
            CASE
                WHEN first_cart_time IS NOT NULL
                THEN 1 ELSE 0
            END
        ) AS cart_sessions,

        SUM(
            CASE
                WHEN first_cart_time IS NOT NULL
                 AND first_purchase_time > first_cart_time
                THEN 1 ELSE 0
            END
        ) AS converted_cart_sessions

    FROM session_first_event
)

SELECT
    view_sessions,
    view_cart_sessions,
    completed_sessions,
    cart_sessions,
    converted_cart_sessions,

    cart_sessions - converted_cart_sessions
        AS abandoned_sessions,

    ROUND(
        view_cart_sessions / view_sessions * 100,
        2
    ) AS view_to_cart_rate,

    ROUND(
        completed_sessions / view_cart_sessions * 100,
        2
    ) AS cart_to_purchase_rate,

    ROUND(
        completed_sessions / view_sessions * 100,
        2
    ) AS overall_rate,

    ROUND(
        converted_cart_sessions / cart_sessions * 100,
        2
    ) AS cart_conversion_rate,

    ROUND(
        (cart_sessions - converted_cart_sessions)
        / cart_sessions * 100,
        2
    ) AS abandonment_rate

FROM x;
CREATE OR REPLACE VIEW bi_monthly_abandonment AS

SELECT
    DATE_FORMAT(first_cart_time, '%Y-%m') AS event_month,

    COUNT(*) AS cart_sessions,

    SUM(
        CASE
            WHEN first_purchase_time > first_cart_time
            THEN 1 ELSE 0
        END
    ) AS converted_sessions,

    SUM(
        CASE
            WHEN first_purchase_time IS NULL
              OR first_purchase_time <= first_cart_time
            THEN 1 ELSE 0
        END
    ) AS abandoned_sessions,

    ROUND(
        SUM(
            CASE
                WHEN first_purchase_time IS NULL
                  OR first_purchase_time <= first_cart_time
                THEN 1 ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS abandonment_rate,

    ROUND(
        SUM(
            CASE
                WHEN first_purchase_time > first_cart_time
                THEN 1 ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS cart_conversion_rate

FROM session_first_event

WHERE first_cart_time IS NOT NULL

GROUP BY DATE_FORMAT(first_cart_time, '%Y-%m');
CREATE OR REPLACE VIEW bi_abandonment_breakdown AS

WITH x AS (
    SELECT
        SUM(
            CASE
                WHEN first_cart_time IS NOT NULL
                 AND (
                        first_purchase_time IS NULL
                        OR first_purchase_time <= first_cart_time
                     )
                 AND first_remove_time > first_cart_time
                THEN 1 ELSE 0
            END
        ) AS removed_abandonment,

        SUM(
            CASE
                WHEN first_cart_time IS NOT NULL
                 AND (
                        first_purchase_time IS NULL
                        OR first_purchase_time <= first_cart_time
                     )
                 AND (
                        first_remove_time IS NULL
                        OR first_remove_time <= first_cart_time
                     )
                THEN 1 ELSE 0
            END
        ) AS silent_abandonment

    FROM session_first_event
)

SELECT
    '主动移除后放弃' AS abandonment_type,
    removed_abandonment AS sessions
FROM x

UNION ALL

SELECT
    '静默放弃',
    silent_abandonment
FROM x;

CREATE OR REPLACE VIEW bi_repeat_purchase AS

SELECT
    CASE
        WHEN frequency = 1
        THEN '单次购买用户'
        ELSE '复购用户'
    END AS purchase_type,

    COUNT(*) AS users,

    ROUND(
        COUNT(*) / SUM(COUNT(*)) OVER() * 100,
        2
    ) AS user_share,

    ROUND(SUM(monetary), 2) AS revenue,

    ROUND(
        SUM(monetary)
        / SUM(SUM(monetary)) OVER()
        * 100,
        2
    ) AS revenue_share,

    ROUND(AVG(monetary), 2) AS avg_monetary

FROM user_rfm

GROUP BY
    CASE
        WHEN frequency = 1
        THEN '单次购买用户'
        ELSE '复购用户'
    END;

-- 由相同 SQL 公式生成分解视图，替代手工录入；单位为百分点。
CREATE OR REPLACE VIEW bi_conversion_decomposition AS
WITH segment_funnel AS (

    SELECT
        event_month,
        user_type,

        SUM(has_view) AS view_users,

        SUM(
            CASE
                WHEN has_view = 1
                 AND has_cart = 1
                 AND has_purchase = 1
                THEN 1 ELSE 0
            END
        ) AS complete_users

    FROM user_monthly_profile

    WHERE event_month IN ('2019-11', '2019-12')

    GROUP BY
        event_month,
        user_type
),

month_total AS (

    SELECT
        event_month,
        SUM(view_users) AS total_view_users

    FROM segment_funnel

    GROUP BY event_month
),

metrics AS (

    SELECT
        s.event_month,
        s.user_type,

        s.view_users / t.total_view_users AS view_share,

        s.complete_users
        / NULLIF(s.view_users, 0) AS conversion_rate

    FROM segment_funnel s

    JOIN month_total t
      ON s.event_month = t.event_month
),

nov AS (

    SELECT *
    FROM metrics
    WHERE event_month = '2019-11'

),

december AS (

    SELECT *
    FROM metrics
    WHERE event_month = '2019-12'

),

effects AS (

    SELECT
        n.user_type,

        /* 结构变化的影响 */
        (n.view_share - d.view_share)
        * d.conversion_rate
        AS composition_effect,

        /* 用户本身转化率变化的影响 */
        n.view_share
        * (n.conversion_rate - d.conversion_rate)
        AS conversion_effect

    FROM nov n

    JOIN december d
      ON n.user_type = d.user_type
)

SELECT
    user_type,

    ROUND(
        composition_effect * 100,
        2
    ) AS composition_effect_pp,

    ROUND(
        conversion_effect * 100,
        2
    ) AS conversion_effect_pp,

    ROUND(
        (composition_effect + conversion_effect) * 100,
        2
    ) AS total_effect_pp

FROM effects

UNION ALL

SELECT
    '合计',

    ROUND(
        SUM(composition_effect) * 100,
        2
    ),

    ROUND(
        SUM(conversion_effect) * 100,
        2
    ),

    ROUND(
        SUM(composition_effect + conversion_effect) * 100,
        2
    )

FROM effects;
