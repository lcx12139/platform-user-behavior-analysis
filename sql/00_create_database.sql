-- 分析目的：创建分析数据库。适用 MySQL 8.0+；已有库无需重复初始化。
-- 不自动删除已有数据或汇总表；已有库请仅执行结果查询部分。
CREATE DATABASE IF NOT EXISTS user_behavior_analysis
CHARACTER SET utf8mb4;
