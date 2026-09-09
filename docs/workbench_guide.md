# 在 MySQL Workbench 中运行

## 已有数据库：当前使用场景

连接原有 MySQL 实例，在查询标签页先执行只读检查：

```sql
USE user_behavior_analysis;
SHOW TABLES;
SHOW INDEX FROM user_behavior;
SHOW COLUMNS FROM session_first_event;
```

已有约 1,958 万行明细时，不要再次运行 02_load_data.sql，否则会追加重复数据。

- 04、05：只读查询，可复核；ARPPU 已改成正价格购买用户分母。
- 06—09：包含建汇总表、填充和结果查询。对应表已存在且数据完整时，只选中末尾完整的 WITH ... SELECT ...; 运行，不执行整份文件。
- 09：已有 first_remove_time 时不要重复 ALTER；缺少该字段时先检查旧表状态，再单独运行相应 ALTER 和 remove 汇总插入。
- 10、11：对已有 session_first_event 做只读分析；11 需要 first_remove_time。
- 03：对照 SHOW INDEX，仅执行缺少的索引语句；不删除已有额外索引。

选中完整语句块（包含 WITH 和最终 SELECT），点击执行选中语句按钮。无选区时可能运行整个编辑区，执行导入或建表文件前先确认选区。

## 从零复现

在隔离的新环境按 00—11 顺序执行。脚本显式使用 user_behavior_analysis；仅切换侧栏默认 schema 不会覆盖脚本中的 USE。换库时必须一致修改所有显式库名。

使用查询编辑器中的 LOAD DATA LOCAL INFILE，不使用 Import Wizard。检查本机 CSV 路径，确保客户端连接和服务器允许 LOCAL INFILE。可先运行 SHOW VARIABLES LIKE 'local_infile'; 检查服务端状态。配置按实际报错处理，仓库不保存密码。

每次只执行一个月的 LOAD DATA，紧接着运行 SHOW WARNINGS; 再继续下个月。CSV 使用 CRLF。导入后按 methodology.md 核对总行数、月份、周末字段及空 Session。

## 核对与限制

与 findings.md 中已报告结果比较。Session 全部加购的转化率与严格 View→Cart→Purchase 第二步转化率有不同分母，不可替换。首次行为近似和空字符串 Session 限制见 methodology.md。

本次整理未连接你的 Workbench/MySQL 实例；未声称 SQL 已在该环境实际执行。
