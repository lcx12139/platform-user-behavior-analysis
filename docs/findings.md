# Findings and interpretation

All analysis numbers are supplied by the project owner unless an explicit local verification is noted. They describe recorded behavior during October 2019–February 2020. This repository preparation is not a new database analysis run.

## Scale and first observation

The local aggregate [cleaning summary](cleaning_summary.csv) supports 20,692,840 raw rows, 1,109,098 duplicates and 19,583,742 cleaned rows. Monthly distinct-user counts in that file are **not** monthly first-observed counts and must not be added to estimate unique users.

| Month | First-observed users |
|---|---:|
| 2019-10 | 399,664 |
| 2019-11 | 313,436 |
| 2019-12 | 299,461 |
| 2020-01 | 328,938 |
| 2020-02 | 297,859 |
| Total | 1,639,358 |

These users first appear in this observation window; registration and acquisition dates are unknown.

## Funnel definitions compared

| Grain and definition | View | Qualified view + cart | Complete | View→cart | Cart→purchase | Overall |
|---|---:|---:|---:|---:|---:|---:|
| User broad | 1,597,754 | 358,026 | 104,757 | 22.41% | 29.26% | 6.56% |
| User first-time strict | 1,597,754 | 269,901 | 71,783 | 16.89% | 26.60% | 4.49% |
| Session first-time strict | 4,280,702 | 587,038 | 71,321 | 13.71% | 12.15% | 1.67% |

The old local broad-funnel CSV matches the supplied first row. Other funnel counts have not been independently recomputed in MySQL during this refactor. The lower session rate demonstrates the importance of grain and ordering; it does not identify the causal effect of any business action.

## Monthly user-level broad funnel

| Month | View users | View + cart | Complete | View→cart | Cart→purchase | Overall |
|---|---:|---:|---:|---:|---:|---:|
| 2019-10 | 388,331 | 123,260 | 23,938 | 31.74% | 19.42% | 6.16% |
| 2019-11 | 355,643 | 84,260 | 29,532 | 23.69% | 35.05% | 8.30% |
| 2019-12 | 358,212 | 72,359 | 23,711 | 20.20% | 32.77% | 6.62% |
| 2020-01 | 397,775 | 81,202 | 26,295 | 20.41% | 32.38% | 6.61% |
| 2020-02 | 379,246 | 78,315 | 23,990 | 20.65% | 30.63% | 6.33% |

October has the highest observed view-to-cart progression but lowest broad cart-to-purchase rate. November has the highest overall broad rate; the improvement from October accompanies increased cart-to-purchase, not increased view-to-cart. Monthly users overlap, so these counts do not sum to observation-window unique users.

## Cart abandonment and removal

| Measure | Sessions / rate |
|---|---:|
| Cart sessions | 985,781 |
| Converted | 125,246 |
| Abandoned | 860,535 |
| First remove after first cart | 290,131 |
| Abandoned with qualifying remove | 219,608 |
| Silent abandoned | 640,927 |
| Cart abandonment | 87.29% |
| Cart conversion | 12.71% |
| Remove / cart | 29.43% |
| Remove share of abandonment | 25.52% |
| Silent share of abandonment | 74.48% |

Most abandonment is classified without a qualifying first-remove signal. This motivates monitoring incomplete cart sessions in addition to removal events. It does not prove that no later removal occurred or that price, payment failures or insufficient discounts caused abandonment.

## Monthly cart outcomes

Attribution is the month of first cart, not necessarily the month of purchase or removal.

| Month | Cart | Converted | Abandoned | Abandoned with remove | Silent | Abandonment | Remove share | Silent share |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 2019-10 | 228,146 | 24,292 | 203,854 | 42,295 | 161,559 | 89.35% | 20.75% | 79.25% |
| 2019-11 | 212,125 | 29,017 | 183,108 | 49,646 | 133,462 | 86.32% | 27.11% | 72.89% |
| 2019-12 | 164,511 | 23,185 | 141,326 | 37,941 | 103,385 | 85.91% | 26.85% | 73.15% |
| 2020-01 | 195,508 | 25,819 | 169,689 | 46,239 | 123,450 | 86.79% | 27.25% | 72.75% |
| 2020-02 | 185,491 | 22,933 | 162,558 | 43,487 | 119,071 | 87.64% | 26.75% | 73.25% |

October combines high monthly broad view-to-cart (31.74%) with high session cart abandonment (89.35%); its all-cart session conversion is about 10.65%. These use different populations and should be described together, not multiplied into a single funnel. November leads the monthly **broad overall** funnel; December has the lowest cart abandonment, so November is not best on every metric.

## Proposed follow-up, not completed findings

Instrument checkout steps and payment outcomes; investigate segment differences; examine returning users and delayed cross-session purchases. Define testable hypotheses before intervention. Retention, RFM, revenue structure, brand/product splits and Power BI remain future work. No revenue values, causal claims or uplift estimates are supplied here.
