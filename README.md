# Olist Cohort Retention Analysis

A monthly cohort retention analysis of the Olist Brazilian e-commerce marketplace, built entirely in Oracle SQL (cohort assignment, period indexing, and the retention matrix are all computed in SQL, not pandas) and rendered through a Jupyter notebook.

## What's in this project

| File / folder | Covers |
|---|---|
| [`README_DATASETS.md`](README_DATASETS.md) | Schema and contents of the three source CSVs (customers, orders, order_items) |
| [`README_SQL.md`](README_SQL.md) | The standalone `Olist.sql` script — CTE structure and all 15 queries |
| [`README_NOTEBOOK.md`](README_NOTEBOOK.md) | The `olist.ipynb` notebook — its section-by-section structure |
| [`charts/`](charts/) + [`charts/README_CHARTS.md`](charts/README_CHARTS.md) | Five exported PNG charts and what each one shows |

## Methodology in one paragraph

Every delivered order is linked to its customer's `customer_unique_id` (not `customer_id`, which Olist regenerates per order — see `README_DATASETS.md`). Each customer is assigned a `cohort_month` (the month of their first-ever delivered order), and every subsequent order gets a `period_number` (months elapsed since that cohort month). Retention is then expressed as the percentage of each cohort's period-0 size still active in later periods — computed entirely with CTEs and conditional aggregation in Oracle SQL, then loaded into pandas only for charting.

## Key results

- **Overall verdict: repeat purchasing is weak.** Four independent metrics agree: period-based retention, the shape of the retention curve past period 1, lifetime "ever returned" rate, and the new-vs-repeat customer trend.
- **Period 0 → Period 1: 100% → 5.0%** — a 95-point drop, confirmed real (not a data artifact) by checking that the cohort count barely changes at period 1.
- **Retention floor:** after period 1, rates stay flat at 0.0–0.7% through period 6 — almost all churn happens in the first month; nothing meaningfully worsens after that.
- **Lifetime ceiling:** even the cohort with the longest observation window (19 months) tops out at 7.3% ever returning for a second order.
- **Repeat share over time:** climbs slowly from ~0.1% to a peak of 3.0% across 18 months, then dips — new customers make up 97%+ of activity in every month observed.
- **Growth phase is over:** monthly new-customer cohorts grew from 262 (2016-10) to 7,060 (2017-11), then plateaued at 5,800–6,800 through 2018 — meaning repeat purchase, not new acquisition, is the only lever left for organic growth.

## Caveats to carry into any business decision

- Extremes from very small samples (a cohort or state with fewer than ~50 customers) are noise, not signal — see `charts/README_CHARTS.md` for specific examples (AP state, n=64).
- Regional and timing patterns found here are correlational. None of them establish *why* customers do or don't return (product category, delivery experience, etc. were not tested) — they describe *what* happens, not *what causes it*.

## Suggested next step

Since nearly all churn happens within the first 30 days after an order, re-engagement efforts (follow-up offers, second-purchase incentives) aimed at that exact window carry the highest expected return — targeting customers past day 60–90 is working against data that shows the window has already closed.
