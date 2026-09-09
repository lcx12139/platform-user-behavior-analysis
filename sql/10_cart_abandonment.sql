-- All cart sessions, no view requirement. First purchase must follow first cart to convert.
-- MySQL 8.0+. Run in numeric order on a fresh database; do not blindly rerun loads.
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
