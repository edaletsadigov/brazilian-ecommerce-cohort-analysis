
--Q1 Restrict to orders with order_status = 'delivered'
with delivered as (
select 
order_id,
customer_id,
ORDER_PURCHASE_TIMESTAMP,
order_status
from OLIST_ORDERS
where order_status = 'delivered')
select * from delivered;

--Q2 cohort CTE: per customer_unique_id, cohort_month = month of MIN(order_purchase_timestamp)
WITH delivered AS (
    SELECT 
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
cohort AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(MIN(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')), 'MM') AS cohort_month
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
    GROUP BY oc.customer_unique_id
)
SELECT * FROM cohort;

--Q3 activity CTE: per customer per order, the order_month
WITH delivered as (
    SELECT 
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
cohort as (
    SELECT
        oc.customer_unique_id,
        TRUNC(MIN(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')), 'MM') AS cohort_month
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
    GROUP BY oc.customer_unique_id
),
activity as (
    select
    oc.customer_unique_id,
    trunc(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS'),'MM') as order_month
    from OLIST_CUSTOMERS oc
    join delivered d
    on d.customer_id = oc.CUSTOMER_ID)
select ac.customer_unique_id, order_month, cohort_month from activity ac
join cohort coh
on ac.customer_unique_id = coh.customer_unique_id;

--Q4 Join the two and compute period_number = month difference between order_month and cohort_month
WITH delivered AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
cohort AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(MIN(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')), 'MM') AS cohort_month
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
    GROUP BY oc.customer_unique_id
),
activity AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS'), 'MM') AS order_month
    FROM olist_customers oc
    JOIN delivered d
        ON d.customer_id = oc.customer_id
)
SELECT
    ac.customer_unique_id,
    ac.order_month,
    coh.cohort_month,
    MONTHS_BETWEEN(ac.order_month, coh.cohort_month) AS period_number
FROM activity ac
JOIN cohort coh
    ON ac.customer_unique_id = coh.customer_unique_id
    where MONTHS_BETWEEN(ac.order_month, coh.cohort_month) > 0;

--Q5 Retention matrix: cohort_month x period_number -> COUNT(DISTINCT customer)
WITH delivered AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
cohort AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(MIN(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')), 'MM') AS cohort_month
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
    GROUP BY oc.customer_unique_id
),
activity AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS'), 'MM') AS order_month
    FROM olist_customers oc
    JOIN delivered d
        ON d.customer_id = oc.customer_id
),
period AS (
    SELECT
        ac.customer_unique_id,
        coh.cohort_month,
        MONTHS_BETWEEN(ac.order_month, coh.cohort_month) AS period_number
    FROM activity ac
    JOIN cohort coh
        ON ac.customer_unique_id = coh.customer_unique_id
)
SELECT
    cohort_month,
    COUNT(DISTINCT CASE WHEN period_number = 0 THEN customer_unique_id END) AS period_0,
    COUNT(DISTINCT CASE WHEN period_number = 1 THEN customer_unique_id END) AS period_1,
    COUNT(DISTINCT CASE WHEN period_number = 2 THEN customer_unique_id END) AS period_2,
    COUNT(DISTINCT CASE WHEN period_number = 3 THEN customer_unique_id END) AS period_3,
    COUNT(DISTINCT CASE WHEN period_number = 4 THEN customer_unique_id END) AS period_4,
    COUNT(DISTINCT CASE WHEN period_number = 5 THEN customer_unique_id END) AS period_5,
    COUNT(DISTINCT CASE WHEN period_number = 6 THEN customer_unique_id END) AS period_6
FROM period
GROUP BY cohort_month
ORDER BY cohort_month;

--Q6 Cohort sizes: the period 0 count for each cohort
WITH delivered AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
cohort AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(MIN(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')), 'MM') AS cohort_month
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
    GROUP BY oc.customer_unique_id
)
select 
    cohort_month,
    count(distinct customer_unique_id) as cohort_size
from cohort
group by cohort_month
order by cohort_month;

--Q7 Retention rate matrix: each cell divided by its cohort's period 0 size
WITH delivered AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
cohort AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(MIN(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')), 'MM') AS cohort_month
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
    GROUP BY oc.customer_unique_id
),
activity AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS'), 'MM') AS order_month
    FROM olist_customers oc
    JOIN delivered d
        ON d.customer_id = oc.customer_id
),
period AS (
    SELECT
        ac.customer_unique_id,
        coh.cohort_month,
        MONTHS_BETWEEN(ac.order_month, coh.cohort_month) AS period_number
    FROM activity ac
    JOIN cohort coh
        ON ac.customer_unique_id = coh.customer_unique_id
),
matrix AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT CASE WHEN period_number = 0 THEN customer_unique_id END) AS period_0,
        COUNT(DISTINCT CASE WHEN period_number = 1 THEN customer_unique_id END) AS period_1,
        COUNT(DISTINCT CASE WHEN period_number = 2 THEN customer_unique_id END) AS period_2,
        COUNT(DISTINCT CASE WHEN period_number = 3 THEN customer_unique_id END) AS period_3,
        COUNT(DISTINCT CASE WHEN period_number = 4 THEN customer_unique_id END) AS period_4,
        COUNT(DISTINCT CASE WHEN period_number = 5 THEN customer_unique_id END) AS period_5,
        COUNT(DISTINCT CASE WHEN period_number = 6 THEN customer_unique_id END) AS period_6
    FROM period
    GROUP BY cohort_month
)
SELECT
    cohort_month,
    period_0,
    ROUND(period_0 / NULLIF(period_0, 0) * 100, 1) AS pct_0,
    ROUND(period_1 / NULLIF(period_0, 0) * 100, 1) AS pct_1,
    ROUND(period_2 / NULLIF(period_0, 0) * 100, 1) AS pct_2,
    ROUND(period_3 / NULLIF(period_0, 0) * 100, 1) AS pct_3,
    ROUND(period_4 / NULLIF(period_0, 0) * 100, 1) AS pct_4,
    ROUND(period_5 / NULLIF(period_0, 0) * 100, 1) AS pct_5,
    ROUND(period_6 / NULLIF(period_0, 0) * 100, 1) AS pct_6
FROM matrix
ORDER BY cohort_month;

--Q8 Average retention rate per period across all cohorts
WITH delivered AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
cohort AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(MIN(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')), 'MM') AS cohort_month
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
    GROUP BY oc.customer_unique_id
),
activity AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS'), 'MM') AS order_month
    FROM olist_customers oc
    JOIN delivered d
        ON d.customer_id = oc.customer_id
),
period AS (
    SELECT
        ac.customer_unique_id,
        coh.cohort_month,
        MONTHS_BETWEEN(ac.order_month, coh.cohort_month) AS period_number
    FROM activity ac
    JOIN cohort coh
        ON ac.customer_unique_id = coh.customer_unique_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS size_0
    FROM cohort
    GROUP BY cohort_month
),
max_date AS (
    SELECT MAX(order_month) AS max_order_month FROM activity
),
periods AS (
    SELECT LEVEL - 1 AS period_number
    FROM dual
    CONNECT BY LEVEL <= 7         
),
grid AS (
    SELECT cs.cohort_month, p.period_number, cs.size_0
    FROM cohort_size cs
    CROSS JOIN periods p
    CROSS JOIN max_date md
    WHERE ADD_MONTHS(cs.cohort_month, p.period_number) <= md.max_order_month
),
actuals AS (
    SELECT cohort_month, period_number, COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM period
    GROUP BY cohort_month, period_number
)
SELECT
    g.period_number,
    COUNT(*) AS cohorts_observed,
    ROUND(AVG(NVL(a.active_customers, 0) / g.size_0 * 100), 1) AS avg_retention_pct
FROM grid g
LEFT JOIN actuals a
    ON a.cohort_month = g.cohort_month AND a.period_number = g.period_number
GROUP BY g.period_number
ORDER BY g.period_number;

--Q9 Best and worst cohort by month-1 retention
WITH delivered AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
cohort AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(MIN(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')), 'MM') AS cohort_month
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
    GROUP BY oc.customer_unique_id
),
activity AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS'), 'MM') AS order_month
    FROM olist_customers oc
    JOIN delivered d
        ON d.customer_id = oc.customer_id
),
period AS (
    SELECT
        ac.customer_unique_id,
        coh.cohort_month,
        MONTHS_BETWEEN(ac.order_month, coh.cohort_month) AS period_number
    FROM activity ac
    JOIN cohort coh
        ON ac.customer_unique_id = coh.customer_unique_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS size_0
    FROM cohort
    GROUP BY cohort_month
),
month1_actual AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS size_1
    FROM period
    WHERE period_number = 1
    GROUP BY cohort_month
),
max_date AS (
    SELECT MAX(order_month) AS max_order_month FROM activity
),
month1_rate AS (
    SELECT
        cs.cohort_month,
        cs.size_0,
        NVL(m1.size_1, 0) AS size_1,
        ROUND(NVL(m1.size_1, 0) / cs.size_0 * 100, 1) AS pct_month1
    FROM cohort_size cs
    LEFT JOIN month1_actual m1
        ON m1.cohort_month = cs.cohort_month
    CROSS JOIN max_date md
    WHERE ADD_MONTHS(cs.cohort_month, 1) <= md.max_order_month
)
SELECT * FROM (
    SELECT cohort_month, size_0, pct_month1, 'BEST' AS label
    FROM month1_rate
    ORDER BY pct_month1 DESC
    FETCH FIRST 1 ROW ONLY
)
UNION ALL
SELECT * FROM (
    SELECT cohort_month, size_0, pct_month1, 'WORST' AS label
    FROM month1_rate
    ORDER BY pct_month1 ASC
    FETCH FIRST 1 ROW ONLY
);

--Q10 Revenue per cohort per period, using the order items table
WITH delivered AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
cohort AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(MIN(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')), 'MM') AS cohort_month
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
    GROUP BY oc.customer_unique_id
),
order_revenue AS (
    SELECT
        order_id,
        SUM(price) AS revenue          
    FROM olist_order_items
    GROUP BY order_id
),
activity AS (
    SELECT
        d.order_id,
        oc.customer_unique_id,
        TRUNC(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS'), 'MM') AS order_month
    FROM olist_customers oc
    JOIN delivered d
        ON d.customer_id = oc.customer_id
),
period AS (
    SELECT
        ac.order_id,
        ac.customer_unique_id,
        coh.cohort_month,
        MONTHS_BETWEEN(ac.order_month, coh.cohort_month) AS period_number
    FROM activity ac
    JOIN cohort coh
        ON ac.customer_unique_id = coh.customer_unique_id
)
SELECT
    p.cohort_month,
    SUM(CASE WHEN p.period_number = 0 THEN r.revenue ELSE 0 END) AS revenue_0,
    SUM(CASE WHEN p.period_number = 1 THEN r.revenue ELSE 0 END) AS revenue_1,
    SUM(CASE WHEN p.period_number = 2 THEN r.revenue ELSE 0 END) AS revenue_2,
    SUM(CASE WHEN p.period_number = 3 THEN r.revenue ELSE 0 END) AS revenue_3,
    SUM(CASE WHEN p.period_number = 4 THEN r.revenue ELSE 0 END) AS revenue_4,
    SUM(CASE WHEN p.period_number = 5 THEN r.revenue ELSE 0 END) AS revenue_5,
    SUM(CASE WHEN p.period_number = 6 THEN r.revenue ELSE 0 END) AS revenue_6
FROM period p
JOIN order_revenue r
    ON r.order_id = p.order_id
GROUP BY p.cohort_month
ORDER BY p.cohort_month;

--Q11 — Compute month-1 retention rate per customer_state (states with cohort size ≥ 50 only). Return the top 5 and bottom 5 states.
WITH delivered AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
customer_first_order AS (
    SELECT
        oc.customer_unique_id,
        oc.customer_state,
        TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS') AS order_date,
        ROW_NUMBER() OVER (
            PARTITION BY oc.customer_unique_id
            ORDER BY TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')
        ) AS rn
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
),
cohort AS (
    SELECT
        customer_unique_id,
        customer_state,
        TRUNC(order_date, 'MM') AS cohort_month
    FROM customer_first_order
    WHERE rn = 1
),
activity AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS'), 'MM') AS order_month
    FROM olist_customers oc
    JOIN delivered d
        ON d.customer_id = oc.customer_id
),
period AS (
    SELECT
        ac.customer_unique_id,
        coh.customer_state,
        coh.cohort_month,
        MONTHS_BETWEEN(ac.order_month, coh.cohort_month) AS period_number
    FROM activity ac
    JOIN cohort coh
        ON ac.customer_unique_id = coh.customer_unique_id
),
max_date AS (
    SELECT MAX(order_month) AS max_order_month FROM activity
),
censored_cohort AS (
    SELECT c.*
    FROM cohort c
    CROSS JOIN max_date md
    WHERE ADD_MONTHS(c.cohort_month, 1) <= md.max_order_month
),
state_size AS (
    SELECT customer_state, COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM censored_cohort
    GROUP BY customer_state
),
state_month1 AS (
    SELECT p.customer_state, COUNT(DISTINCT p.customer_unique_id) AS size_1
    FROM period p
    JOIN censored_cohort cc
        ON cc.customer_unique_id = p.customer_unique_id
    WHERE p.period_number = 1
    GROUP BY p.customer_state
),
state_rate AS (
    SELECT
        ss.customer_state,
        ss.cohort_size,
        NVL(sm.size_1, 0) AS size_1,
        ROUND(NVL(sm.size_1, 0) / ss.cohort_size * 100, 1) AS pct_month1
    FROM state_size ss
    LEFT JOIN state_month1 sm
        ON sm.customer_state = ss.customer_state
    WHERE ss.cohort_size >= 50
)
SELECT * FROM (
    SELECT customer_state, cohort_size, pct_month1, 'TOP' AS rank_group
    FROM state_rate
    ORDER BY pct_month1 DESC
    FETCH FIRST 5 ROWS ONLY
)
UNION ALL
SELECT * FROM (
    SELECT customer_state, cohort_size, pct_month1, 'BOTTOM' AS rank_group
    FROM state_rate
    ORDER BY pct_month1 ASC
    FETCH FIRST 5 ROWS ONLY
)
ORDER BY 4, 3 DESC;

--Q12 — For customers with more than one order, compute the day gap between their first and second order, then bucket it (0-30, 31-60, 61-90, 90+ days). Count customers per bucket.
WITH delivered AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
customer_orders AS (
    SELECT
        oc.customer_unique_id,
        TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS') AS order_date,
        ROW_NUMBER() OVER (
            PARTITION BY oc.customer_unique_id
            ORDER BY TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')
        ) AS rn
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
),
first_order AS (
    SELECT customer_unique_id, order_date AS first_date
    FROM customer_orders
    WHERE rn = 1
),
second_order AS (
    SELECT customer_unique_id, order_date AS second_date
    FROM customer_orders
    WHERE rn = 2
),
gap AS (
    SELECT
        f.customer_unique_id,
        f.first_date,
        s.second_date,
        TRUNC(s.second_date) - TRUNC(f.first_date) AS day_gap
    FROM first_order f
    JOIN second_order s
        ON s.customer_unique_id = f.customer_unique_id
),
bucketed AS (
    SELECT
        customer_unique_id,
        day_gap,
        CASE
            WHEN day_gap BETWEEN 0 AND 30 THEN '0-30'
            WHEN day_gap BETWEEN 31 AND 60 THEN '31-60'
            WHEN day_gap BETWEEN 61 AND 90 THEN '61-90'
            ELSE '90+'
        END AS gap_bucket
    FROM gap
)
SELECT
    gap_bucket,
    COUNT(*) AS customer_count
FROM bucketed
GROUP BY gap_bucket
ORDER BY
    CASE gap_bucket
        WHEN '0-30'  THEN 1
        WHEN '31-60' THEN 2
        WHEN '61-90' THEN 3
        WHEN '90+'   THEN 4
    END;

--Q13 — For each order month, compute the % of orders from new customers (period_number = 0) vs repeat customers (period_number > 0). Show the trend over time.
WITH delivered AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
cohort AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(MIN(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')), 'MM') AS cohort_month
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
    GROUP BY oc.customer_unique_id
),
activity AS (
    SELECT
        oc.customer_unique_id,
        TRUNC(TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS'), 'MM') AS order_month
    FROM olist_customers oc
    JOIN delivered d
        ON d.customer_id = oc.customer_id
),
period AS (
    SELECT
        ac.customer_unique_id,
        ac.order_month,
        coh.cohort_month,
        MONTHS_BETWEEN(ac.order_month, coh.cohort_month) AS period_number
    FROM activity ac
    JOIN cohort coh
        ON ac.customer_unique_id = coh.customer_unique_id
),
monthly AS (
    SELECT
        order_month,
        COUNT(DISTINCT CASE WHEN period_number = 0 THEN customer_unique_id END) AS new_customers,
        COUNT(DISTINCT CASE WHEN period_number > 0 THEN customer_unique_id END) AS repeat_customers,
        COUNT(DISTINCT customer_unique_id) AS total_customers
    FROM period
    GROUP BY order_month
)
SELECT
    order_month,
    new_customers,
    repeat_customers,
    total_customers,
    ROUND(new_customers / total_customers * 100, 1) AS pct_new,
    ROUND(repeat_customers / total_customers * 100, 1) AS pct_repeat
FROM monthly
ORDER BY order_month;

--Q14 — For each cohort, compute the % of members who ever placed a second order (lifetime survival, not period-specific). Show how this rate moves across cohorts.
WITH delivered AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_timestamp,
        order_status
    FROM olist_orders
    WHERE order_status = 'delivered'
),
customer_orders AS (
    SELECT
        oc.customer_unique_id,
        TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS') AS order_date,
        ROW_NUMBER() OVER (
            PARTITION BY oc.customer_unique_id
            ORDER BY TO_DATE(d.order_purchase_timestamp, 'YYYY-MM-DD HH24:MI:SS')
        ) AS rn
    FROM delivered d
    JOIN olist_customers oc
        ON d.customer_id = oc.customer_id
),
cohort AS (
    SELECT
        customer_unique_id,
        TRUNC(order_date, 'MM') AS cohort_month
    FROM customer_orders
    WHERE rn = 1
),
ever_returned AS (
    SELECT
        customer_unique_id,
        MAX(rn) AS total_orders
    FROM customer_orders
    GROUP BY customer_unique_id
),
max_date AS (
    SELECT TRUNC(MAX(order_date), 'MM') AS max_order_month FROM customer_orders
),
cohort_survival AS (
    SELECT
        c.cohort_month,
        er.customer_unique_id,
        CASE WHEN er.total_orders >= 2 THEN 1 ELSE 0 END AS returned_flag
    FROM cohort c
    JOIN ever_returned er
        ON er.customer_unique_id = c.customer_unique_id
)
SELECT
    cs.cohort_month,
    COUNT(*) AS cohort_size,
    SUM(cs.returned_flag) AS returned_customers,
    ROUND(SUM(cs.returned_flag) / COUNT(*) * 100, 1) AS pct_ever_returned,
    ROUND(MONTHS_BETWEEN(md.max_order_month, cs.cohort_month), 0) AS months_observed
FROM cohort_survival cs
CROSS JOIN max_date md
GROUP BY cs.cohort_month, md.max_order_month
ORDER BY cs.cohort_month;
