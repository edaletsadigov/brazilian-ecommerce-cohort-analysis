# Datasets README

This project uses three tables from the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Together they support a monthly cohort retention analysis of Olist's marketplace customers.

## 1. `olist_customers_dataset.csv`

One row per **order-level customer record** (not one row per real person — see the note below).

| Column | Type | Description |
|---|---|---|
| `customer_id` | string | Order-level customer key. Unique per order, **not** unique per real person. |
| `customer_unique_id` | string | The true, persistent identifier for a real customer across all of their orders. |
| `customer_zip_code_prefix` | integer | First digits of the customer's postal code. |
| `customer_city` | string | Customer's city. |
| `customer_state` | string | Customer's state (2-letter Brazilian state code, e.g. `SP`, `RJ`). |

**Size:** 99,441 rows | 99,441 unique `customer_id` | **96,096 unique `customer_unique_id`** | 27 distinct states.

> **Critical trap:** Olist generates a new `customer_id` for every order, even for a returning customer. Any analysis that groups by `customer_id` instead of `customer_unique_id` will treat every returning customer as a brand-new one, producing a flat 0% retention curve. All cohort logic in this project joins on `customer_id` only to link an order to its customer record, then immediately aggregates by `customer_unique_id`.

## 2. `olist_orders_dataset.csv`

One row per order, with the full delivery timeline.

| Column | Type | Description |
|---|---|---|
| `order_id` | string | Unique order identifier. |
| `customer_id` | string | Foreign key to `olist_customers_dataset.customer_id`. |
| `order_status` | string | Order lifecycle status (see breakdown below). |
| `order_purchase_timestamp` | string (datetime) | When the order was placed — the anchor for all cohort/period logic. |
| `order_approved_at` | string (datetime) | When payment was approved. |
| `order_delivered_carrier_date` | string (datetime) | When the order was handed to the logistics carrier. |
| `order_delivered_customer_date` | string (datetime) | When the order reached the customer. |
| `order_estimated_delivery_date` | string (datetime) | Estimated delivery date shown to the customer at checkout. |

**Size:** 99,441 rows | date range **2016-09-04 to 2018-10-17**.

**`order_status` breakdown:**

| Status | Count |
|---|---|
| delivered | 96,478 |
| shipped | 1,107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |

The cohort analysis restricts to `order_status = 'delivered'` (96,478 orders) as its base population; `canceled`/`unavailable` orders are used separately (see Q15) to compare repeat-purchase behavior by first-order outcome.

## 3. `olist_order_items_dataset.csv`

One row per **item within an order** (an order with 3 products has 3 rows here).

| Column | Type | Description |
|---|---|---|
| `order_id` | string | Foreign key to `olist_orders_dataset.order_id`. |
| `order_item_id` | integer | Sequence number of the item within the order. |
| `product_id` | string | Product identifier. |
| `seller_id` | string | Seller identifier. |
| `shipping_limit_date` | string (datetime) | Seller's shipping deadline for this item. |
| `price` | float | Item price (product value only, excludes freight). |
| `freight_value` | float | Shipping cost charged for this item. |

**Size:** 112,650 rows | 98,666 unique orders | 32,951 unique products | 3,095 unique sellers.

Used for the revenue-retention matrix (Q10): item `price` is summed per `order_id` before joining to the cohort/period structure, since a single order can contain multiple item rows.

## Relationships

```
olist_customers_dataset.customer_id  ──┐
                                        ├──> olist_orders_dataset.customer_id
olist_customers_dataset.customer_unique_id  (real person, used for all cohort grouping)

olist_orders_dataset.order_id  ──> olist_order_items_dataset.order_id
```

