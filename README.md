# Platform User Behavior & Growth Analysis

互联网平台用户行为与增长分析 · Conversion, sessions and user operations

An analysis portfolio built around **20.69M raw events**, **19.58M cleaned events** and **1.64M observed users**, using Python and MySQL to distinguish long-window behavioral conversion from conversion within a visit.

**Power BI dashboard: In progress**

## 1. Project Overview

This project examines activity, funnel progression and cart abandonment in five months of cosmetics e-commerce logs. The focus is platform behavior and operational analysis: methods that can inform questions in travel, gaming and other internet products, with domain-specific definitions and validation. Results here describe this dataset only.

The project combines data cleaning, database loading, reusable summary tables and business interpretation. Retention, RFM and user segmentation are planned extensions, not completed analyses.

## 2. Business Questions

- How does observed activity change across days and months?
- How much does measured conversion change when event order and sessions are required?
- Does monthly funnel variation occur before or after cart addition?
- How much cart abandonment includes an explicit removal event?
- How can repeat analysis avoid repeatedly aggregating nearly 20M fact rows?

## 3. Dataset

Source: [E-Commerce Events History in Cosmetics Shop — Kaggle](https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-cosmetics-shop), October 2019–February 2020. Source access and applicable dataset terms remain with the publisher; this repository's code license does not license the dataset.

| Measure | Value |
|---|---:|
| Raw events | 20,692,840 |
| Duplicate events removed | 1,109,098 (5.36%) |
| Cleaned events | 19,583,742 |
| Distinct observed users | 1,639,358 |

Due to dataset size, raw behavioral logs are not included in this repository.

**Evidence status:** results below come from the project owner's completed analysis. Local cleaning totals and the existing broad-funnel export provide supporting artifacts. The repository refactor did not rerun the MySQL analyses. Numerical results are not embedded in executable analysis SQL. See [findings](docs/findings.md) and [review notes](docs/review_notes.md).

## 4. Data Pipeline

```mermaid
flowchart LR
    A[Kaggle monthly CSVs] --> B[Python normalization and deduplication]
    B --> C[MySQL LOAD DATA LOCAL INFILE]
    C --> D[user_behavior fact table]
    D --> E[User, month and session summaries]
    E --> F[SQL metrics and documented findings]
    F -. planned .-> G[Power BI dashboard]
```

### Reproduce

**Already using MySQL Workbench with existing data?** Follow the [Workbench guide](docs/workbench_guide.md). Run result queries against existing summaries; do not repeat loads or existing table/index creation.

Use Python 3.10+ and MySQL 8.0+. Install `requirements.txt` in a virtual environment. Download the five source CSVs into `data/raw/`, preserving their original filenames.

```bash
python -m pip install -r requirements.txt
python python/clean_data.py
python python/data_quality_check.py
```

Existing outputs are protected: use `--output-dir data/cleaned_rerun` for a separate cleaning run, then explicitly update import paths if you want to use those files. A complete month is loaded into memory; allow memory for the dataframe and deduplication copies.

Execute `sql/00_...` through `sql/11_...` in numeric order in a **fresh development database**. SQL files select `user_behavior_analysis` explicitly. Edit CSV paths in `02_load_data.sql` for another machine. Enable LOCAL INFILE in both server and client settings; provide credentials through your client, never in source files. Inspect `SHOW WARNINGS` immediately after each import and validate row counts before continuing.

For an existing database, inspect existing tables and indexes first. Loads are append-only and **must not be blindly rerun**. Summary scripts build static snapshots and will fail if those tables already exist. No script drops or truncates existing tables. Rebuild summaries deliberately in a separate database after data changes. SQL has been organized for MySQL; live execution remains to be verified in the owner's environment.

## 5. Data Cleaning

- Read `category_id` as a string to preserve long identifiers.
- Trim and lowercase event types; parse timestamps as UTC and store timezone-naive UTC values.
- Coerce prices to numeric, then remove full-row duplicates **within each monthly file**, before filling missing brand/category values.
- Fill missing `brand` and `category_code` with `Unknown`.
- Preserve missing sessions, negative prices and zero prices in behavioral logs.
- Add date, month, hour, weekday (Monday = 0) and weekend fields.

**Behavior and monetary metrics use different quality rules.** Behavior metrics retain all prices. Purchase Revenue includes only `event_type = 'purchase' AND price > 0`; ARPU divides it by all active users, and ARPPU divides it by positive-price purchasing users in the same period. The ARPPU denominator was explicitly confirmed during this refactor.

February contains 53,812 zero-price events: 31,442 cart, 17,136 remove, 5,234 view and zero purchase events (owner-reported; see validation notes). They are not deleted. Details: [data dictionary](docs/data_dictionary.md) and [methodology](docs/methodology.md).

## 6. Database Design

`user_behavior_analysis.user_behavior` retains event-level detail. `category_id` uses `VARCHAR(30)`; price uses `DECIMAL(10,2)`. There is no supplied event ID, order ID or quantity.

| Summary table | Grain | Purpose |
|---|---|---|
| `user_funnel_summary` | user | View/cart/purchase presence flags |
| `monthly_funnel_summary` | month × user | Within-month presence flags |
| `user_first_event` | user | First view/cart/purchase times |
| `session_first_event` | session identifier | First view/cart/purchase/remove times |

Sessions use the supplied identifier, not a reconstructed inactivity threshold. Missing or shared identifiers are a validation concern; see methodology.

## 7. Performance Optimization

The original repeated `GROUP BY user_id` with conditional maxima over nearly 20M rows was reported to run for more than ten minutes in some attempts. The workflow instead builds reusable summaries through event-specific aggregation and key-based inserts/updates, then queries those smaller tables.

The target fact-table indexes are `idx_user_date(user_id, event_date)` and `idx_event_user(event_type, user_id)`. They align with user/date and event-filtered queries. The legacy index file differed from the owner-confirmed list; the organized script uses the confirmed target and does not drop existing indexes. Inspect actual indexes before running it.

This moves substantial work into summary construction; it does not eliminate the cost of scanning data. No measured speedup multiplier is claimed. Query plans, summary build times and before/after timings remain to be collected on a documented machine.

## 8. KPI Framework

| Metric | Definition |
|---|---|
| DAU / MAU | Distinct users with any recorded behavior per day/month |
| Purchasing users | Distinct users with any purchase event per day |
| Purchase Revenue | Sum of positive purchase-event prices |
| ARPU | Purchase Revenue / active users in the same period |
| ARPPU | Purchase Revenue / positive-price purchasing users in the same period |
| First-observed users | Users grouped by their earliest observed date in the five-month window |

Revenue is an event-price measure, not traditional order GMV. No registration timestamp is available. SQL for basic metrics is included; unavailable KPI outputs are not invented.

## 9. Funnel Analysis

The **user-level broad funnel** tests co-occurrence anywhere in the observation window, without event order or session constraints.

| Stage | Users |
|---|---:|
| View | 1,597,754 |
| View + cart | 358,026 |
| View + cart + purchase | 104,757 |

View → cart: **22.41%**; cart → purchase: **29.26%**; overall: **6.56%**. Each later stage is nested within the preceding stage. These are not immediate conversion rates.

## 10. Strict Funnel Analysis

The **user-level strict funnel** requires `first_view_time < first_cart_time < first_purchase_time`. It yields 269,901 ordered view/cart users and 71,783 completed users: **16.89%**, **26.60%** and **4.49%**, respectively.

This is a first-event approximation, not full path recognition. A user with an early cart followed by a later valid view/cart/purchase path can be excluded. Broad co-occurrence gives a higher rate than this approximation; neither is a validated ground-truth conversion measure.

## 11. Session Funnel Analysis

Within each supplied session identifier, the same first-event conditions yield 4,280,702 view sessions, 587,038 ordered view/cart sessions and 71,321 completed sessions.

| Definition | View → cart | Cart → purchase | Overall |
|---|---:|---:|---:|
| User-level broad | 22.41% | 29.26% | 6.56% |
| User-level strict approximation | 16.89% | 26.60% | 4.49% |
| Session-level strict approximation | 13.71% | 12.15% | 1.67% |

Long-window user-level conversion is higher than conversion within a recorded session. These levels use different populations and denominators; their difference is not an incremental causal effect or a complete user-lifecycle estimate.

## 12. Cart Abandonment Analysis

Among **985,781 cart sessions**, 125,246 have first purchase after first cart; 860,535 do not, giving **87.29% abandonment** and **12.71% conversion**. This starts with all cart sessions and does not require a prior view, unlike the strict session funnel.

Of abandoned sessions, 219,608 have first remove after first cart and 640,927 do not. Thus **74.48%** are operationally classified as “silent abandonment.” This means no qualifying first-remove signal; it does not prove the complete absence of removal later in the session.

## 13. Key Findings

- October has the highest monthly broad view-to-cart rate (31.74%) and highest cart-session abandonment (89.35%). Higher observed cart progression coexists with lower subsequent session conversion.
- November has the highest monthly broad overall conversion (8.30%). Compared with October, broad cart-to-purchase rises from 19.42% to 35.05%, while view-to-cart declines.
- Most classified abandonment lacks a qualifying explicit removal signal. Monitoring remove events alone misses much of the abandonment defined here.

Complete monthly tables and first-observed counts are in [findings](docs/findings.md).

## 14. Business Implications

Prioritize investigating the cart-to-purchase step and distinguish explicit removal from other incomplete cart sessions. Add checkout, payment outcome and error instrumentation before attributing abandonment to a cause. If additional lawful data become available, compare device, product and user segments and test interventions prospectively.

These are proposed investigations, not proven causes, completed experiments or measured revenue opportunities. There is no evidence here that promotions, prices or payment failures explain monthly changes.

## 15. Limitations

The observation window is bounded; first observed does not mean newly registered. First-event funnels can miss valid later sequences, exclude timestamp ties and mix products. Session IDs are supplied by the source, with missing-value import behavior and multi-user collisions still requiring database checks. Cross-session purchases may occur after an apparently abandoned cart session. “Silent” is an operational first-time classification. No channel, campaign, order quantity or payment-failure data supports causal explanations.

## 16. Tech Stack

Python / pandas · MySQL 8.0+ / SQL · Git / GitHub repository preparation · Power BI (planned dashboard).

## 17. Repository Structure

```text
.
├── README.md
├── LICENSE
├── .gitignore
├── requirements.txt
├── python/
│   ├── clean_data.py
│   └── data_quality_check.py
├── sql/                         # 00–11: schema, load, indexes and analysis
├── docs/
│   ├── data_dictionary.md
│   ├── methodology.md
│   ├── findings.md
│   ├── cleaning_summary.csv     # Reviewed aggregate-only exception
│   └── review_notes.md
├── images/README_PLACEHOLDER.md
└── powerbi/README.md
```

Raw/cleaned logs and original-script backups remain local and ignored. The repository contains no dashboard screenshots or fabricated PBIX file.

## 18. Future Work

- New vs. returning observed users and cohort retention.
- RFM and user value segmentation with explicit observation dates.
- Revenue structure, metric-change investigation and brand/product breakdowns.
- Complete-path sequence validation and session-ID quality checks.
- Reproducible query-plan and runtime benchmarks.
- Power BI dashboard with documented KPI definitions.
