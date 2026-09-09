-- Remove means FIRST remove after FIRST cart. Monthly attribution = first-cart month.
-- MySQL 8.0+. Run in numeric order on a fresh database; do not blindly rerun loads.
USE user_behavior_analysis;

WITH cart_behavior AS (
    SELECT
        COUNT(
            CASE
                WHEN first_cart_time IS NOT NULL
                THEN 1
            END
        ) AS cart_sessions,

        -- Cart之后出现Purchase
        COUNT(
            CASE
                WHEN first_cart_time IS NOT NULL
                 AND first_purchase_time > first_cart_time
                THEN 1
            END
        ) AS converted_sessions,

        -- Cart之后没有Purchase
        COUNT(
            CASE
                WHEN first_cart_time IS NOT NULL
                 AND (
                     first_purchase_time IS NULL
                     OR first_purchase_time <= first_cart_time
                 )
                THEN 1
            END
        ) AS abandoned_sessions,

        -- Cart之后出现Remove
        COUNT(
            CASE
                WHEN first_cart_time IS NOT NULL
                 AND first_remove_time > first_cart_time
                THEN 1
            END
        ) AS removed_sessions,

        -- 放弃购买，同时有Cart后的Remove行为
        COUNT(
            CASE
                WHEN first_cart_time IS NOT NULL
                 AND (
                     first_purchase_time IS NULL
                     OR first_purchase_time <= first_cart_time
                 )
                 AND first_remove_time > first_cart_time
                THEN 1
            END
        ) AS abandoned_with_remove

    FROM session_first_event
)

SELECT
    cart_sessions,
    converted_sessions,
    abandoned_sessions,
    removed_sessions,
    abandoned_with_remove,

    abandoned_sessions - abandoned_with_remove
        AS silent_abandoned_sessions,

    ROUND(
        removed_sessions / NULLIF(cart_sessions, 0) * 100,
        2
    ) AS remove_rate,

    ROUND(
        abandoned_with_remove / NULLIF(abandoned_sessions, 0) * 100,
        2
    ) AS remove_share_of_abandonment,

    ROUND(
        (abandoned_sessions - abandoned_with_remove)
        / NULLIF(abandoned_sessions, 0) * 100,
        2
    ) AS silent_abandonment_share

FROM cart_behavior;


WITH monthly_cart AS (
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

        SUM(
            CASE
                WHEN (
                    first_purchase_time IS NULL
                    OR first_purchase_time <= first_cart_time
                )
                AND first_remove_time > first_cart_time
                THEN 1 ELSE 0
            END
        ) AS abandoned_with_remove

    FROM session_first_event

    WHERE first_cart_time IS NOT NULL

    GROUP BY DATE_FORMAT(first_cart_time, '%Y-%m')
)

SELECT
    event_month,
    cart_sessions,
    converted_sessions,
    abandoned_sessions,

    abandoned_with_remove,

    abandoned_sessions - abandoned_with_remove
        AS silent_abandoned_sessions,

    ROUND(
        abandoned_sessions / NULLIF(cart_sessions, 0) * 100,
        2
    ) AS abandonment_rate,

    ROUND(
        abandoned_with_remove / NULLIF(abandoned_sessions, 0) * 100,
        2
    ) AS remove_share,

    ROUND(
        (abandoned_sessions - abandoned_with_remove)
        / NULLIF(abandoned_sessions, 0) * 100,
        2
    ) AS silent_share

FROM monthly_cart

ORDER BY event_month;
