-- 分析目的：配置已确认的明细表索引；先执行 SHOW INDEX，仅运行缺少的索引语句。
-- 不自动删除已有数据或汇总表；已有库请仅执行结果查询部分。
USE user_behavior_analysis;

CREATE INDEX idx_user_date ON user_behavior (user_id, event_date);
CREATE INDEX idx_event_user ON user_behavior (event_type, user_id);
SHOW INDEX FROM user_behavior;
