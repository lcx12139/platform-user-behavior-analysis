# Methodology and metric contracts

## Cleaning and loading

The original implementation reads one monthly file at a time. It normalizes event type, converts UTC timestamps and prices, removes duplicates across all columns in that normalized dataframe, then fills brand/category nulls. Thus “duplicate” means identical after normalization, not necessarily identical raw bytes. Deduplication does not span files. The current code preserves this order and does not introduce chunk-level deduplication.

Missing sessions and all nonpositive-price events remain in the behavioral dataset. Monetary measures use only positive purchase prices. Negative/zero events are not deleted to improve financial metrics. Data quality checks are read-only, chunked and do not certify whole-dataset uniqueness.

The cleaner refuses existing output paths, writes CRLF explicitly and uses project-relative defaults. Existing CSVs remain untouched. If a run is interrupted, use a fresh output directory after investigating the partial file. The SQL loader consumes CSV fields by position and expects CRLF, avoiding the previously reported trailing carriage-return truncation of `is_weekend`.

Import validation, in the MySQL client:

```sql
-- Run SHOW WARNINGS immediately after each individual LOAD DATA statement.
SHOW WARNINGS;
SELECT COUNT(*) AS fact_rows FROM user_behavior; -- expected owner result: 19583742
SELECT event_month, COUNT(*) AS event_count
FROM user_behavior GROUP BY event_month ORDER BY event_month;
SELECT is_weekend, LENGTH(is_weekend) AS value_length, COUNT(*) AS event_count
FROM user_behavior GROUP BY is_weekend, LENGTH(is_weekend);
SELECT COUNT(*) AS null_sessions FROM user_behavior WHERE user_session IS NULL;
SELECT COUNT(*) AS empty_sessions FROM user_behavior WHERE user_session = '';
SELECT user_session, COUNT(DISTINCT user_id) AS users_per_session
FROM user_behavior WHERE user_session IS NOT NULL
GROUP BY user_session HAVING COUNT(DISTINCT user_id) > 1 LIMIT 20;
```

**Import/session limitation:** pandas writes missing sessions as empty CSV fields; the original LOAD DATA maps them directly into VARCHAR. Its SQL filter excludes NULL but does not exclude empty strings. The organized SQL preserves that behavior rather than silently changing published session counts. The actual database's empty-string handling has not been inspected. Check it before reproducing session results; if blanks are grouped together or identifiers map to multiple users, record and approve a revised session contract, rerun metrics and keep the old and corrected results distinct. Do not claim that all missing-session rows were already excluded.

## Metric definitions

| Measure | Numerator | Denominator / grain |
|---|---|---|
| DAU / MAU | Distinct observed users | Day / month, all events |
| Daily purchasing users | Distinct users with purchase | Day, any purchase price |
| Purchase Revenue | Sum(price) for purchase AND price > 0 | Same reporting period |
| ARPU | Purchase Revenue | All active users in period |
| ARPPU | Purchase Revenue | Distinct positive-price purchase users in period |
| First-observed users | Users at their minimum observed date | Month of that date |

ARPPU now uses the owner's explicitly confirmed denominator. Previous SQL counted all purchase users in that denominator. No new ARPPU numerical result is reported because the database has not been rerun. Revenue is a sum of event prices and cannot establish order GMV, unit sales, net revenue or refunds.

## Funnel contracts

- **User broad:** one row per user; nested presence of view, cart and purchase anywhere in the observation window. Order, session and product are unrestricted.
- **Monthly broad:** one row per month/user; the same nested presence within a calendar month.
- **User strict approximation:** first view < first cart < first purchase for the user across the window.
- **Session strict approximation:** same inequalities within `user_session`, grouped by that identifier alone as in the original SQL. The carried user_id is metadata chosen by the original event-specific MIN(user_id) insert logic, not a validated composite key.

View→cart = qualified view/cart entities divided by view entities. Cart→purchase = completed entities divided by qualified view/cart entities. Overall = completed divided by view entities. Rates are percentages rounded to two decimal places; NULLIF guards empty denominators.

Equal timestamps do not qualify. A later valid path after an earlier out-of-order event may be missed. The SQL does not require the same product, enforce a conversion-time window or reconstruct every event sequence. It therefore cannot establish a true lifecycle or instantaneous conversion rate.

## Cart and removal contracts

Cart population: any session with first_cart_time. Converted: first_purchase_time > first_cart_time. Abandoned: first purchase is NULL or <= first cart. No view is required, which explains why this denominator differs from the session funnel.

Removed: first_remove_time > first_cart_time. Abandoned with remove: both abandoned and removed. Silent abandoned: abandoned minus abandoned with remove. Silent therefore means no qualifying **first** removal after first cart; it can include sessions with a later removal if their first removal occurred earlier. Monthly cart metrics are attributed to the first-cart month, and later purchase/removal timestamps are not additionally restricted to that month.

## Engineering and refresh

Summary tables materialize analysis grain. The broad and strict user summaries are assembled from event-specific inserts, retaining the existing optimization pattern. Session summaries use the original first-time aggregation. Their primary keys support upserts. Only the two owner-confirmed fact indexes are supplied. Existing extra indexes are neither automatically created nor dropped.

Summaries are snapshots. Scripts are intended for ordered execution on an empty analysis schema; repeat execution is not an incremental refresh pipeline. Static SQL review cannot substitute for MySQL execution, EXPLAIN or runtime measurement. Existing MySQL data and server settings were not modified during repository preparation.
