# Data dictionary

The fact table is `user_behavior_analysis.user_behavior`. One row represents a retained event, not an order or a session. There is no reliable supplied event primary key.

| Column | MySQL type | Meaning / handling |
|---|---|---|
| event_time | DATETIME | UTC timestamp, stored without timezone; invalid input becomes NaT in Python |
| event_type | VARCHAR(30) | Trimmed lowercase view/cart/remove_from_cart/purchase |
| product_id | BIGINT | Product identifier |
| category_id | VARCHAR(30) | Category identifier; read as string to preserve precision |
| category_code | VARCHAR(255) | Category label; missing filled with Unknown |
| brand | VARCHAR(100) | Brand; missing filled with Unknown |
| price | DECIMAL(10,2) | Event price; negative and zero values retained |
| user_id | BIGINT | Observed user identifier, not proof of registration |
| user_session | VARCHAR(50) | Supplied session identifier; missing records retained in fact data |
| event_date | DATE | UTC calendar date derived from event_time |
| event_month | VARCHAR(7) | YYYY-MM |
| event_hour | TINYINT | UTC hour 0–23 |
| event_weekday | TINYINT | Monday = 0, Sunday = 6 |
| is_weekend | VARCHAR(5) | Python boolean serialized as True/False |

The existing cleaned files use `year_month`, `hour`, `weekday`. The refactored cleaner writes `event_month`, `event_hour`, `event_weekday` in the same positions. The import explicitly maps columns by position, so the old files remain usable and have not been rewritten.

Timestamp/price parsing uses `errors='coerce'` as in the original cleaner. Invalid values are not automatically removed; inspect quality output and MySQL warnings before analysis. The existing weekday comparison yields False for a missing timestamp; such a row must not be interpreted as a validated weekday observation.
