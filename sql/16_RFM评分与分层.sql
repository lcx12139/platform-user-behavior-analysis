-- 分析目的：按最终固定阈值计算 R/F 分数，以金额累计分布计算 M 分数，再进行互斥分层。
-- 最终口径：替代历史 NTILE 评分；F 必须 >=1。CASE 按书写顺序首次匹配，保留原优先级。
USE user_behavior_analysis;

-- 已有 user_rfm_score 时请使用现有汇总或在隔离库重建；不自动删除。

CREATE TABLE user_rfm_score AS

WITH scored AS (
    SELECT
        user_id,
        last_purchase_date,
        recency_days,
        frequency,
        monetary,

        /* R：越近越高 */
        CASE
            WHEN recency_days <= 30  THEN 5
            WHEN recency_days <= 60  THEN 4
            WHEN recency_days <= 90  THEN 3
            WHEN recency_days <= 120 THEN 2
            ELSE 1
        END AS r_score,

        /* F：按照实际购买Session次数 */
        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency BETWEEN 4 AND 5 THEN 4
            ELSE 5
        END AS f_score,

        /* M：按照累计消费金额的五分位 */
        CUME_DIST() OVER(
            ORDER BY monetary
        ) AS monetary_pct

    FROM user_rfm
)

SELECT
    user_id,
    last_purchase_date,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,

    CASE
        WHEN monetary_pct <= 0.20 THEN 1
        WHEN monetary_pct <= 0.40 THEN 2
        WHEN monetary_pct <= 0.60 THEN 3
        WHEN monetary_pct <= 0.80 THEN 4
        ELSE 5
    END AS m_score

FROM scored;


SELECT
    r_score,
    COUNT(*) AS users,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS user_share
FROM user_rfm_score
GROUP BY r_score
ORDER BY r_score;

SELECT
    f_score,
    COUNT(*) AS users,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS user_share
FROM user_rfm_score
GROUP BY f_score
ORDER BY f_score;

SELECT
    m_score,
    COUNT(*) AS users,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS user_share
FROM user_rfm_score
GROUP BY m_score
ORDER BY m_score;

-- 已有 user_value_segment 时请使用现有汇总或在隔离库重建；不自动删除。

CREATE TABLE user_value_segment AS
SELECT
    user_id,
    last_purchase_date,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,

    CASE

        /* 最近买、高频、高消费 */
        WHEN r_score >= 4
         AND f_score >= 3
         AND m_score >= 4
        THEN '核心价值用户'

        /* 高频高消费，但距离最近购买较久 */
        WHEN r_score <= 3
         AND f_score >= 3
         AND m_score >= 4
        THEN '高价值复购用户'

        /* 最近活跃，价值中等，有培养潜力 */
        WHEN r_score >= 4
         AND (
                f_score >= 2
                OR m_score >= 3
             )
        THEN '潜力用户'

        /* 最近购买，但只有一次购买 */
        WHEN r_score >= 4
         AND f_score = 1
        THEN '新近单购用户'

        /* 很久没购买，而且价值较低 */
        WHEN r_score <= 2
         AND f_score <= 2
         AND m_score <= 3
        THEN '沉睡用户'

        /* 曾有较高购买价值，但近期已经不购买 */
        WHEN r_score <= 2
         AND (
                f_score >= 3
                OR m_score >= 4
             )
        THEN '流失风险用户'

        ELSE '一般用户'

    END AS user_segment

FROM user_rfm_score;

SELECT
    user_segment,

    COUNT(*) AS users,

    ROUND(
        COUNT(*) / SUM(COUNT(*)) OVER() * 100,
        2
    ) AS user_share,

    ROUND(SUM(monetary), 2) AS revenue,

    ROUND(
        SUM(monetary) / SUM(SUM(monetary)) OVER() * 100,
        2
    ) AS revenue_share,

    ROUND(AVG(monetary), 2) AS avg_monetary,

    ROUND(AVG(frequency), 2) AS avg_frequency,

    ROUND(AVG(recency_days), 2) AS avg_recency

FROM user_value_segment

GROUP BY user_segment

ORDER BY revenue DESC;

SELECT
    COUNT(*) AS paying_users,

    SUM(
        CASE
            WHEN frequency >= 2
            THEN 1 ELSE 0
        END
    ) AS repeat_buyers,

    ROUND(
        SUM(
            CASE
                WHEN frequency >= 2
                THEN 1 ELSE 0
            END
        ) / COUNT(*) * 100,
        2
    ) AS repeat_purchase_rate

FROM user_rfm;
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
