# SQL README — `Olist.sql`

Standalone Oracle SQL script containing the raw queries for the cohort retention analysis, developed and tested independently of the notebook. This is the "source of truth" for the query logic that the notebook later re-runs through `pd.read_sql()`.

## Dialect

Oracle SQL (tested against Oracle 19c / Oracle XE `XEPDB1`). Key Oracle-specific functions used throughout: `TO_DATE`, `TRUNC(date, 'MM')`, `MONTHS_BETWEEN`, `ADD_MONTHS`, `NVL`, `ROW_NUMBER() OVER (...)`, `FETCH FIRST n ROWS ONLY`, `CONNECT BY LEVEL`.

## Prerequisites

Three tables must exist and be populated before running any query below:

```sql
SELECT * FROM OLIST_CUSTOMERS;
SELECT * FROM OLIST_ORDERS;
SELECT * FROM OLIST_ORDER_ITEMS;
```

Load these from `olist_customers_dataset.csv`, `olist_orders_dataset.csv`, and `olist_order_items_dataset.csv` respectively (see `README_DATASETS.md` for their schemas).

## Query inventory

The file contains 15 queries (`Q1`–`Q15`), each preceded by a `--` comment stating what it answers. They build on each other through a shared CTE chain:

- **`delivered`** — orders filtered to `order_status = 'delivered'`. The base population for every query except Q15.
- **`cohort`** — one row per `customer_unique_id`, with `cohort_month` = the truncated month of their earliest delivered order.
- **`activity`** — one row per delivered order, with its truncated order month.
- **`period`** — joins `activity` to `cohort` to compute `period_number = MONTHS_BETWEEN(order_month, cohort_month)`.

From there:

| Query | Builds on | Adds |
|---|---|---|
| Q1–Q4 | — | The four CTEs above, established incrementally |
| Q5 | `period` | Pivots into a cohort × period customer-count matrix via `COUNT(DISTINCT CASE WHEN ...)` |
| Q6 | `cohort` | Period-0 cohort sizes (the retention baseline) |
| Q7 | Q5 logic | Converts counts to percentages of each cohort's own size |
| Q8 | Q7 logic + a `periods` CTE (`CONNECT BY LEVEL`) | Average retention curve, with a `grid` CTE that excludes cohort/period combinations that haven't happened yet (censoring) |
| Q9 | Q6 + Q7 logic | Best/worst single cohort by month-1 retention, censoring-aware |
| Q10 | `period` + `olist_order_items` | Revenue retention matrix (item `price`, pre-aggregated per order before joining) |
| Q11 | Rebuilds `cohort` on `customer_state` via `ROW_NUMBER()` | Top/bottom 5 states by month-1 retention, `cohort_size >= 50` filter |
| Q12 | New `customer_orders` CTE with `ROW_NUMBER()` | Day-gap buckets between a customer's 1st and 2nd order |
| Q13 | `period` | New-vs-repeat customer share per calendar month |
| Q14 | `customer_orders` + `ever_returned` | Lifetime "ever placed a 2nd order" rate per cohort |


## Methodology notes embedded via query design

- **`customer_unique_id` vs. `customer_id`:** every cohort/period CTE joins on `customer_id` (to link an order to its customer row) but groups and counts by `customer_unique_id` (the real person). Using `customer_id` for grouping would treat each of a customer's orders as a different person and collapse retention to 0%.
- **Censoring:** Q8, Q9, Q11, and (implicitly) Q14 exclude cohort/period combinations that haven't had time to occur yet, using `ADD_MONTHS(cohort_month, N) <= MAX(order_month)` filters. Without this, the most recent cohorts would show artificially low retention simply because not enough time has passed, not because they performed worse.
- **Compound-query syntax:** several queries (Q9, Q11) use `UNION ALL` to combine a "best/top" branch and a "worst/bottom" branch, each with its own `ORDER BY ... FETCH FIRST n ROWS ONLY`. Each branch is wrapped in its own subquery (`SELECT * FROM (...)`) because Oracle does not allow `ORDER BY`/`FETCH FIRST` on an individual branch of a `UNION ALL` otherwise (`ORA-00933`).

## Known gap

Q5 and Q6 are logically subsumed by Q7 and Q8 respectively (Q7 recomputes the Q5 matrix before converting to percentages; Q8's `grid`/`actuals` CTEs recompute what Q6 already returns). They are kept as separate, standalone queries in this file for traceability with the assignment's numbered requirements, not because the pipeline requires re-running them.

