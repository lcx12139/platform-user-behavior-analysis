# 数据字典

事实表：`user_behavior_analysis.user_behavior`。一行是一条保留的行为事件，不是订单或完整会话；没有来源提供的唯一事件ID。

| 字段 | MySQL类型 | 含义与处理 |
|---|---|---|
| event_time | DATETIME | UTC解析后去时区，日期无效时转为空值 |
| event_type | VARCHAR(30) | 去空格并转小写：view/cart/remove_from_cart/purchase |
| product_id | BIGINT | 商品标识 |
| category_id | VARCHAR(30) | 品类标识，Python按字符串读取 |
| category_code | VARCHAR(255) | 品类代码，缺失填Unknown |
| brand | VARCHAR(100) | 品牌，缺失填Unknown |
| price | DECIMAL(10,2) | 事件价格；保留负数和零 |
| user_id | BIGINT | 观察用户标识，不等于注册证明 |
| user_session | VARCHAR(50) | 来源提供的会话标识，明细保留缺失记录 |
| event_date | DATE | UTC自然日 |
| event_month | VARCHAR(7) | YYYY-MM |
| event_hour | TINYINT | UTC小时，0—23 |
| event_weekday | TINYINT | 星期一为0，星期日为6 |
| is_weekend | VARCHAR(5) | 周末True/False |

旧清洗文件的year_month/hour/weekday在同一列位置，导入按位置映射，未重写这些CSV。新清洗器使用event_month/event_hour/event_weekday。

| 分析表 | 粒度与作用 |
|---|---|
| user_funnel_summary | 用户：三类行为出现标记 |
| monthly_funnel_summary | 月份×用户：同月行为标记 |
| user_first_event | 用户：首次浏览/加购/购买，仅覆盖这三类行为 |
| session_first_event | 会话标识：四类行为首次时间；user_id仅沿用原聚合元数据 |
| user_monthly_profile | 用户×月份：活跃、首次月份、行为标记、正价格购买与收入 |
| user_rfm | 正价格购买用户：最后购买日期、R/F/M原始值 |
| user_rfm_score | 正价格购买用户：最终R/F/M分数 |
| user_value_segment | 正价格购买用户：互斥价值分层 |

Power BI汇总视图映射见[SQL执行索引](../sql/README.md)。
