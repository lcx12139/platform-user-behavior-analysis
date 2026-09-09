# 数据获取说明

数据源：[Kaggle：E-Commerce Events History in Cosmetics Shop](https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-cosmetics-shop)。从原发布方获取2019-Oct、2019-Nov、2019-Dec、2020-Jan、2020-Feb五个月CSV，放入本地`data/raw/`。

原始20,692,840条，规范化去重后19,583,742条。原始和清洗后明细合计约5.44GB（十进制计量），不纳入GitHub仓库。访问和再使用遵循数据源自身条款；仓库MIT许可不替代数据许可。

运行`python python/clean_data.py`生成`data/cleaned/`下的结果；已有结果时程序拒绝覆盖。重新清洗需指定新的输出目录，并自行在导入SQL中选择对应路径。不要将数据库账号、密码或Kaggle令牌写进项目。

[清洗汇总](../docs/cleaning_summary.csv)是唯一允许提交的CSV例外，只含月度汇总统计。
