# Charts README

Five PNG charts, exported directly from the executed cells of `olist.ipynb`. Each was generated with matplotlib/seaborn from the SQL query results (`q6_result` … `q11_result`) computed in the notebook.

## 01_cohort_retention_heatmap.png

**Source:** `q7_result` | **Type:** Heatmap (seaborn)

Rows are cohort months (2016-10 through 2018-08), columns are period numbers 1–6 (months since first purchase), cell values are the retention rate (%) of each cohort relative to its own period-0 size. Color scale runs from 0% (light) to the observed maximum (dark red).

**Reading it:** every column past period 0 is uniformly near-zero across almost every row — there is no cohort that stands out with a visibly darker band. This is the single clearest visual evidence that retention collapses immediately after the first month, for every cohort, not just a few.

## 02_average_retention_curve.png

**Source:** `q8_result` | **Type:** Line chart with markers

X-axis: period number (0–6). Y-axis: average retention rate (%) across all eligible cohorts for that period (only cohorts old enough to have reached that period are included — see the SQL methodology note on censoring).

**Reading it:** the curve starts at 100% (period 0, by definition) and falls off a cliff to ~5% at period 1, then flattens into a near-zero tail through period 6. The shape is a single sharp drop followed by a flat line — not a gradual decay curve, which is the pattern seen in businesses with habitual repeat usage.

## 03_monthly_cohort_size.png

**Source:** `q6_result` | **Type:** Bar chart

X-axis: cohort month. Y-axis: number of new customers whose first-ever delivered order fell in that month.

**Reading it:** cohort size grows from 262 (2016-10) to a peak of 7,060 (2017-11), then plateaus in the 5,800–6,800 range through 2018. This shows the marketplace's customer-acquisition phase ending roughly a year into the observed period, after which monthly new-customer volume is roughly flat rather than still growing.

## 04_new_vs_repeat_customers.png

**Source:** `q13_result` | **Type:** Stacked area chart

X-axis: order month. Y-axis: share of that month's active customers who are "new" (this is their cohort month) vs. "repeat" (they placed an earlier order in a prior month).

**Reading it:** the repeat share (top band) is nearly invisible for most of the timeline — it grows slowly from ~0% to a peak of ~3.0% (2018-05) before dipping slightly. New customers make up 97%+ of every month's activity throughout the entire dataset.

## 05_top_bottom_states_retention.png

**Source:** `q11_result` | **Type:** Horizontal grouped bar chart

Shows the 5 Brazilian states with the highest and the 5 with the lowest month-1 retention rate, restricted to states with a cohort size of at least 50 customers (to avoid noise from tiny states).

**Reading it:** the two largest states in the dataset, RJ and BA, both land at 0.6% — close to the overall average. Smaller states in both the top and bottom groups (e.g. AP at the top with only 64 customers, AM/AC/TO at the bottom with 0.0%) should be read cautiously — their sample sizes are small enough that the extreme values may not be reliable, even after the ≥50 filter.

## How these charts were produced

All five are generated inside `olist.ipynb`, in the `## Vizualation` section, directly from the Oracle SQL query results loaded via `pd.read_sql()`. No chart uses data that was not first computed in SQL — pandas/matplotlib are used only for final rendering, per the project's technical requirement that cohort/period logic must live in SQL.

