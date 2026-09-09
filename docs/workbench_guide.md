# MySQL Workbench运行指南

## 已有数据库

连接原来的MySQL实例，先执行`USE user_behavior_analysis;`以及`SHOW TABLES;`、`SHOW INDEX FROM user_behavior;`确认对象。数据目录已迁移到D盘并不改变SQL中的数据库名或原始CSV所在路径。

不要重新执行02导入五个月CSV；它会追加数据。06—09、12、15、16同时包含构建汇总与结果查询，已有表时只选中完整的WITH…SELECT或SELECT运行。09已有first_remove_time时不要再次ALTER。03只运行实际缺失的索引语句。

总用户视图定义位于19的`CREATE OR REPLACE VIEW bi_overall_kpi AS ...;`完整语句。该变更只更换视图定义；在Workbench执行后还需在Power BI刷新对应MySQL查询；若另行改成CSV导入，则文件不会自动随视图更新。

新增`bi_conversion_decomposition`沿用17的分解公式，可替代看板手工数据。20用于只读核对总用户、正价格购买及汇总输出；运行大表COUNT可能耗时，不要重复启动同一查询。

## 新环境复现

下载原始数据并清洗后，按[SQL索引](../sql/README.md)依赖执行。所有脚本显式选择user_behavior_analysis；如果换隔离库，要一致修改库名，不能只切换侧栏默认schema。

使用查询编辑器中的LOAD DATA LOCAL INFILE，不使用Import Wizard。按本机路径调整CSV位置，客户端和服务器均需允许LOCAL INFILE。每月导入后立刻执行SHOW WARNINGS；检查总行数19,583,742、月份及is_weekend长度，再继续汇总。

凭据只保存在自己的数据库客户端中，不写进SQL、PBIX分享说明或Git仓库。不要提交MySQL的my.ini或数据目录。
