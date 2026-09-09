# SQL执行索引

适用MySQL 8.0+，使用UTF-8编码。已有数据库请按需求选中完整查询执行，不要从00开始全选运行。新环境按下表依赖准备；重建在隔离库中进行，本次未执行任何数据库建表、导入或刷新。

| 文件 | 用途 | 主要依赖 / 是否写库 |
|---|---|---|
| [00_create_database.sql](00_create_database.sql) | 创建数据库 | 新环境初始化 |
| [01_create_user_behavior.sql](01_create_user_behavior.sql) | 明细表结构 | 00；建表 |
| [02_load_data.sql](02_load_data.sql) | 五个月CSV导入 | 01空表；追加写入，不能重复运行 |
| [03_indexes.sql](03_indexes.sql) | 两个已确认明细索引 | 01；仅创建缺少的索引 |
| [04_basic_metrics.sql](04_basic_metrics.sql) | 基础用户及金额指标 | 明细；只读 |
| [05_user_first_observed.sql](05_user_first_observed.sql) | 首次观察用户 | 明细；只读 |
| [06_user_funnel.sql](06_user_funnel.sql) | 用户宽口径漏斗 | 明细；建汇总及查询 |
| [07_monthly_funnel.sql](07_monthly_funnel.sql) | 月度宽口径漏斗 | 明细；建汇总及查询 |
| [08_strict_user_funnel.sql](08_strict_user_funnel.sql) | 用户首次时间严格近似 | 明细；建汇总及查询 |
| [09_session_funnel.sql](09_session_funnel.sql) | 会话首次时间严格近似 | 明细；建表、加字段及查询 |
| [10_cart_abandonment.sql](10_cart_abandonment.sql) | 全加购会话放弃 | session_first_event；只读 |
| [11_cart_removal_analysis.sql](11_cart_removal_analysis.sql) | 移除和月度放弃 | session_first_event含first_remove_time；只读 |
| [12_用户月度画像.sql](12_用户月度画像.sql) | 用户×月份画像 | 明细；一次性建表和画像索引 |
| [13_用户结构分析.sql](13_用户结构分析.sql) | 新老用户规模、活跃、收入 | 12；只读 |
| [14_Cohort留存分析.sql](14_Cohort留存分析.sql) | 同期群留存长表及矩阵 | 12；只读 |
| [15_RFM基础指标.sql](15_RFM基础指标.sql) | RFM基础与Session检查 | 明细；一次性建表及查询 |
| [16_RFM评分与分层.sql](16_RFM评分与分层.sql) | 最终评分、分层和复购 | 15且F≥1；一次性建表及查询 |
| [17_指标异动分析.sql](17_指标异动分析.sql) | 结构分解、日期/价格/品牌 | 12和明细；只读 |
| [18_字段质量与归因边界.sql](18_字段质量与归因边界.sql) | 2019-11品类缺失 | 明细；只读 |
| [19_PowerBI汇总视图.sql](19_PowerBI汇总视图.sql) | 看板汇总 | 12、15、16、09；创建或替换视图 |
| [20_结果与口径核对.sql](20_结果与口径核对.sql) | 最终一致性验证 | 对应汇总及视图；只读 |

原`1.sql`—`9.sql`及旧RFM评分已保存到本地忽略目录，公开版本不存在两套F评分。后续脚本移除了自动DROP，不会悄悄删除已有表；已有画像或RFM表时使用SELECT部分，重建需另行决定。

19包含原11个汇总视图和新增`bi_conversion_decomposition`。其中`bi_overall_kpi`最终从`user_monthly_profile`按用户去重；金额仍来自正价格购买RFM。分解视图为新老两组加合计行，不应把三行再相加。瀑布图如需按两个效应展示，可透视合计行的两个分解字段。

所有新老标识new/old、阶段View/Cart/Purchase和字段标识保持原值，以免破坏已有模型引用；显示层中文标签在Power BI中单独设置。
