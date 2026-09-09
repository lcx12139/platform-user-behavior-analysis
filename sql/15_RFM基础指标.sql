-- 分析目的：建立正价格购买用户的最近购买间隔、购买频次和累计金额。
-- 最终口径：R 基准日 2020-03-01；F 为不同正价格购买 Session 数，近似订单频次；M 为正价格购买价格之和。
USE user_behavior_analysis;

SELECT
    COUNT(*) AS positive_purchase_events,

    SUM(
        CASE
            WHEN user_session IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_session_events,

    ROUND(
        SUM(
            CASE
                WHEN user_session IS NULL
                THEN 1 ELSE 0
            END
        ) / COUNT(*) * 100,
        4
    ) AS missing_session_rate

FROM user_behavior
WHERE event_type = 'purchase'
  AND price > 0;

  -- 已有 user_rfm 时请使用现有汇总或在隔离库重建；不自动删除。

CREATE TABLE user_rfm AS
SELECT
    user_id,

    /* 最后一次购买日期 */
    MAX(event_date) AS last_purchase_date,

    /* R：距离观察期结束还有多少天 */
    DATEDIFF(
        '2020-03-01',
        MAX(event_date)
    ) AS recency_days,

    /* F：购买Session数，近似订单数 */
    COUNT(
        DISTINCT CASE
            WHEN user_session IS NOT NULL
            THEN user_session
        END
    ) AS frequency,

    /* M：累计正价格购买金额 */
    ROUND(SUM(price), 2) AS monetary

FROM user_behavior

WHERE event_type = 'purchase'
  AND price > 0

GROUP BY user_id;

SELECT
    COUNT(*) AS paying_users,

    ROUND(AVG(recency_days), 2) AS avg_recency,

    ROUND(AVG(frequency), 2) AS avg_frequency,

    ROUND(AVG(monetary), 2) AS avg_monetary,

    MAX(frequency) AS max_frequency,

    ROUND(MAX(monetary), 2) AS max_monetary

FROM user_rfm;

SELECT
    MIN(recency_days) AS min_r,
    MAX(recency_days) AS max_r,

    MIN(frequency) AS min_f,
    MAX(frequency) AS max_f,

    ROUND(MIN(monetary), 2) AS min_m,
    ROUND(MAX(monetary), 2) AS max_m

FROM user_rfm;

SELECT
    frequency,
    COUNT(*) AS users,
    ROUND(
        COUNT(*) / SUM(COUNT(*)) OVER() * 100,
        2
    ) AS user_share
FROM user_rfm
GROUP BY frequency
ORDER BY frequency
LIMIT 20;


-- 正价格购买的空字符串与 NULL 会话分别检查；旧检查只覆盖 NULL。
SELECT SUM(user_session IS NULL) AS null_session_events,
       SUM(user_session = '') AS blank_session_events
FROM user_behavior WHERE event_type = 'purchase' AND price > 0;
-- 后续评分及复购分类前要求 frequency >= 1；出现零值时先核对会话质量。
SELECT COUNT(*) AS invalid_frequency_users FROM user_rfm WHERE frequency < 1;
