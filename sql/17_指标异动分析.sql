-- 分析目的：分解 2019-11 相对 2019-12 的整体转化差异，并做日期、价格带和品牌下钻。
-- 最终口径：结构权重为浏览用户占比，以12月组内转化率作为结构项基准；价格带分析为正价格行为的用户日×价格带，不是月度漏斗。
USE user_behavior_analysis;

SELECT
    event_month,
    user_type,

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
        / NULLIF(SUM(has_view), 0)
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
        / NULLIF(SUM(has_view), 0)
        * 100,
        2
    ) AS overall_rate

FROM user_monthly_profile

WHERE event_month >= '2019-11'

GROUP BY
    event_month,
    user_type

ORDER BY
    event_month,
    user_type;

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
    'TOTAL',

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

WITH daily_user_behavior AS (
    SELECT
        event_date,
        user_id,

        MAX(CASE
                WHEN event_type = 'view'
                THEN 1 ELSE 0
            END) AS has_view,

        MAX(CASE
                WHEN event_type = 'cart'
                THEN 1 ELSE 0
            END) AS has_cart,

        MAX(CASE
                WHEN event_type = 'purchase'
                THEN 1 ELSE 0
            END) AS has_purchase

    FROM user_behavior
    WHERE event_date BETWEEN '2019-11-01' AND '2019-12-31'

    GROUP BY
        event_date,
        user_id
)

SELECT
    event_date,

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
        / NULLIF(SUM(has_view), 0) * 100,
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
        ) * 100,
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
        / NULLIF(SUM(has_view), 0) * 100,
        2
    ) AS overall_rate

FROM daily_user_behavior
GROUP BY event_date
ORDER BY event_date;
WITH purchase_data AS (
    SELECT
        CASE
            WHEN event_date IN (
                '2019-11-21',
                '2019-11-22',
                '2019-11-23',
                '2019-11-24',
                '2019-11-28',
                '2019-11-29',
                '2019-11-30'
            )
            THEN 'Peak'
            ELSE 'Normal'
        END AS period_type,

        CASE
            WHEN price < 5 THEN '0-5'
            WHEN price < 10 THEN '5-10'
            WHEN price < 20 THEN '10-20'
            WHEN price < 50 THEN '20-50'
            ELSE '50+'
        END AS price_band,

        user_id,
        price

    FROM user_behavior

    WHERE event_month = '2019-11'
      AND event_type = 'purchase'
      AND price > 0
)

SELECT
    period_type,
    price_band,

    COUNT(*) AS purchase_events,

    COUNT(DISTINCT user_id) AS paid_users,

    ROUND(SUM(price), 2) AS revenue,

    ROUND(AVG(price), 2) AS avg_purchase_price,

    ROUND(
        COUNT(*) /
        SUM(COUNT(*)) OVER(PARTITION BY period_type)
        * 100,
        2
    ) AS purchase_event_share

FROM purchase_data

GROUP BY
    period_type,
    price_band

ORDER BY
    period_type,
    CASE price_band
        WHEN '0-5' THEN 1
        WHEN '5-10' THEN 2
        WHEN '10-20' THEN 3
        WHEN '20-50' THEN 4
        WHEN '50+' THEN 5
    END;

   WITH user_day_price_behavior AS (

    SELECT
        event_date,

        CASE
            WHEN event_date IN (
                '2019-11-21',
                '2019-11-22',
                '2019-11-23',
                '2019-11-24',
                '2019-11-28',
                '2019-11-29',
                '2019-11-30'
            )
            THEN 'Peak'
            ELSE 'Normal'
        END AS period_type,

        CASE
            WHEN price > 0 AND price < 5 THEN '0-5'
            WHEN price >= 5 AND price < 10 THEN '5-10'
            WHEN price >= 10 AND price < 20 THEN '10-20'
            WHEN price >= 20 AND price < 50 THEN '20-50'
            WHEN price >= 50 THEN '50+'
        END AS price_band,

        user_id,

        MAX(
            CASE
                WHEN event_type = 'view'
                THEN 1 ELSE 0
            END
        ) AS has_view,

        MAX(
            CASE
                WHEN event_type = 'cart'
                THEN 1 ELSE 0
            END
        ) AS has_cart,

        MAX(
            CASE
                WHEN event_type = 'purchase'
                 AND price > 0
                THEN 1 ELSE 0
            END
        ) AS has_purchase

    FROM user_behavior

    WHERE event_month = '2019-11'
      AND price > 0

    GROUP BY
        event_date,
        period_type,
        price_band,
        user_id
)

SELECT
    period_type,
    price_band,

    SUM(has_view) AS view_user_days,

    SUM(
        CASE
            WHEN has_view = 1
             AND has_cart = 1
            THEN 1 ELSE 0
        END
    ) AS view_cart_user_days,

    SUM(
        CASE
            WHEN has_view = 1
             AND has_cart = 1
             AND has_purchase = 1
            THEN 1 ELSE 0
        END
    ) AS complete_user_days,

    ROUND(
        SUM(
            CASE
                WHEN has_view = 1
                 AND has_cart = 1
                THEN 1 ELSE 0
            END
        )
        / NULLIF(SUM(has_view), 0)
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
        / NULLIF(SUM(has_view), 0)
        * 100,
        2
    ) AS overall_rate

FROM user_day_price_behavior

WHERE price_band IS NOT NULL

GROUP BY
    period_type,
    price_band

ORDER BY
    period_type,
    CASE price_band
        WHEN '0-5' THEN 1
        WHEN '5-10' THEN 2
        WHEN '10-20' THEN 3
        WHEN '20-50' THEN 4
        WHEN '50+' THEN 5
    END;

    WITH brand_purchase AS (
    SELECT
        CASE
            WHEN event_date IN (
                '2019-11-21',
                '2019-11-22',
                '2019-11-23',
                '2019-11-24',
                '2019-11-28',
                '2019-11-29',
                '2019-11-30'
            )
            THEN 'Peak'
            ELSE 'Normal'
        END AS period_type,

        brand,
        user_id,
        price

    FROM user_behavior

    WHERE event_month = '2019-11'
      AND event_type = 'purchase'
      AND price > 0
      AND brand IS NOT NULL
),

brand_summary AS (
    SELECT
        period_type,
        brand,

        COUNT(*) AS purchase_events,

        COUNT(DISTINCT user_id) AS paid_users,

        ROUND(SUM(price), 2) AS revenue

    FROM brand_purchase

    GROUP BY
        period_type,
        brand
),

brand_share AS (
    SELECT
        period_type,
        brand,
        purchase_events,
        paid_users,
        revenue,

        ROUND(
            purchase_events
            / SUM(purchase_events) OVER(PARTITION BY period_type)
            * 100,
            2
        ) AS purchase_share,

        ROUND(
            revenue
            / SUM(revenue) OVER(PARTITION BY period_type)
            * 100,
            2
        ) AS revenue_share

    FROM brand_summary
),

ranked AS (
    SELECT
        *,

        ROW_NUMBER() OVER(
            PARTITION BY period_type
            ORDER BY purchase_events DESC
        ) AS rn

    FROM brand_share
)

SELECT *
FROM ranked

WHERE rn <= 15

ORDER BY
    period_type,
    rn;

    WITH brand_purchase AS (
    SELECT
        CASE
            WHEN event_date IN (
                '2019-11-21',
                '2019-11-22',
                '2019-11-23',
                '2019-11-24',
                '2019-11-28',
                '2019-11-29',
                '2019-11-30'
            )
            THEN 'Peak'
            ELSE 'Normal'
        END AS period_type,

        brand

    FROM user_behavior

    WHERE event_month = '2019-11'
      AND event_type = 'purchase'
      AND price > 0
      AND brand IS NOT NULL
),

brand_count AS (
    SELECT
        period_type,
        brand,
        COUNT(*) AS purchase_events

    FROM brand_purchase

    GROUP BY
        period_type,
        brand
),

brand_share AS (
    SELECT
        period_type,
        brand,

        purchase_events,

        purchase_events
        / SUM(purchase_events) OVER(PARTITION BY period_type)
        AS purchase_share

    FROM brand_count
),

comparison AS (
    SELECT
        brand,

        MAX(
            CASE
                WHEN period_type = 'Normal'
                THEN purchase_share
            END
        ) AS normal_share,

        MAX(
            CASE
                WHEN period_type = 'Peak'
                THEN purchase_share
            END
        ) AS peak_share

    FROM brand_share

    GROUP BY brand
)

SELECT
    brand,

    ROUND(normal_share * 100, 2) AS normal_share_pct,

    ROUND(peak_share * 100, 2) AS peak_share_pct,

    ROUND(
        (peak_share - normal_share) * 100,
        2
    ) AS share_change_pp

FROM comparison

WHERE normal_share IS NOT NULL
  AND peak_share IS NOT NULL

ORDER BY share_change_pp DESC

LIMIT 20;

-- 补充可复现查询：按用户日汇总工作日与周末宽口径漏斗。
-- 该补充查询本次未在生产库执行；不把其结果标记为本次已验证。
WITH user_day AS (
 SELECT event_date, user_id, MAX(event_weekday >= 5) AS weekend_flag,
 MAX(event_type = 'view') AS has_view, MAX(event_type = 'cart') AS has_cart,
 MAX(event_type = 'purchase') AS has_purchase
 FROM user_behavior WHERE event_month = '2019-11' GROUP BY event_date, user_id
)
SELECT CASE WHEN weekend_flag = 1 THEN '周末' ELSE '工作日' END AS day_type,
 SUM(has_view) AS view_user_days,
 SUM(has_view = 1 AND has_cart = 1 AND has_purchase = 1) AS complete_user_days,
 ROUND(100.0 * SUM(has_view = 1 AND has_cart = 1 AND has_purchase = 1) / NULLIF(SUM(has_view),0),2) AS overall_rate
FROM user_day GROUP BY weekend_flag;
