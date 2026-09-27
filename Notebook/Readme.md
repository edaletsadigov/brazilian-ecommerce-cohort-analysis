# Notebook README — `olist.ipynb`

Jupyter notebook that runs the full cohort retention pipeline: connects to Oracle, executes each numbered SQL query (Q1–Q14), loads the results into pandas, and renders five charts plus written insights.

## Structure

### 1. Libraries (cells 1–2)
Imports: `sqlalchemy`, `pandas`, `matplotlib.pyplot`, `seaborn`, `getpass`. No SQL logic here.

### 2. Connection (cells 3–4)
Builds a SQLAlchemy engine (`oracle+oracledb` driver) against a local Oracle instance (`localhost:1521`, service `XEPDB1`). Password is requested interactively via `getpass()` — never hardcoded. Cell 4 runs a `SELECT COUNT(*)` smoke test against `olist_customers` to confirm the connection works before anything else runs.

### 3. Questions (cells 5–47) — one query per section
For each question `Q1` through `Q14`, the notebook follows the same two-cell pattern:
```python
qN = """<SQL query as a string>"""
qN_result = pd.read_sql(qN, engine)
qN_result
```
The queries chain the same core CTEs (`delivered`, `cohort`, `activity`, `period`) built up progressively from Q1 to Q4, then reused as building blocks in every later query. Q15 (first-order-status comparison) is not yet included in this notebook.

| Query | What it answers |
|---|---|
| Q1 | Restrict to delivered orders |
| Q2 | Cohort assignment (first purchase month per customer) |
| Q3 | Per-order activity month |
| Q4 | Period number (months since cohort month) |
| Q5 | Retention matrix (customer counts) |
| Q6 | Cohort sizes (period-0 baseline) |
| Q7 | Retention rate matrix (%) |
| Q8 | Average retention curve (censoring-adjusted) |
| Q9 | Best/worst cohort by month-1 retention |
| Q10 | Revenue retention matrix (order_items) |
| Q11 | Top/bottom 5 states by month-1 retention |
| Q12 | Days-to-second-order buckets |
| Q13 | New vs. repeat customer share per month |
| Q14 | Lifetime "ever returned" rate per cohort |

### 4. Vizualation (cells 48–60)
Five charts, each in its own markdown-header + code-cell pair, built directly from the `qN_result` DataFrames above (no new SQL). See `charts/README_CHARTS.md` for what each one shows.

### 5. Insights (cells 61–77)
Eight markdown-only cells, each pairing a specific numeric finding (quoting the exact DataFrame and values it came from) with a one-line business interpretation. No new computation happens here — this section only interprets results already produced above.

## Requirements to run

- Python packages: `sqlalchemy`, `oracledb`, `pandas`, `matplotlib`, `seaborn`
- A running Oracle instance with `olist_customers`, `olist_orders`, and `olist_order_items` tables loaded (see `README_SQL.md` for the load step)
- Valid Oracle credentials for the `Brazilian_olist` schema (entered at runtime, not stored in the notebook)

## Known gaps

- Q15 (canceled/unavailable vs. delivered first-order comparison) has SQL written elsewhere in this project but is not yet a cell in this notebook.
- No `note.md` methodology file is embedded in the notebook itself — insights live as markdown cells here, but a standalone `note.md` (with the `customer_unique_id` trap explanation) is a separate deliverable per the assignment brief.

