-- Confirmed target indexes only. Inspect SHOW INDEX first; run only missing CREATE statements.
-- MySQL 8.0+. Run in numeric order on a fresh database; do not blindly rerun loads.
USE user_behavior_analysis;

CREATE INDEX idx_user_date ON user_behavior (user_id, event_date);
CREATE INDEX idx_event_user ON user_behavior (event_type, user_id);
SHOW INDEX FROM user_behavior;
