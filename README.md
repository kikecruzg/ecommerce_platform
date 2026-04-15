# E-commerce Order Management API

A backend service for an e-commerce platform that exposes a minimal order management API. Customers can place orders, the system finds the optimal warehouse to fulfill them, and processes payment before confirming.

## Stack

| | |
|---|---|
| **Ruby** | 4.0.1 |
| **Rails** | 8.1.3 (API-only mode) |
| **PostgreSQL** | 18.3 |

## How it works

### `POST /orders`

The endpoint executes the following steps in order:

1. **Geocode** the shipping address via `GeocodingService` (mocked — returns random lat/lng)
2. **Select warehouse** — finds all warehouses that have sufficient stock for every requested item, then picks the one closest to the shipping address using the [Haversine formula](https://en.wikipedia.org/wiki/Haversine_formula). Returns `422` if no warehouse can fulfill the order.
3. **Calculate total** — sums `product.price × quantity` for each item.
4. **Charge payment** via `PaymentService` (mocked — always succeeds and returns a generated `payment_id`). Returns `402` if payment fails.
5. **Persist** inside a single database transaction:
   - Creates the `Order` record linked to the customer and warehouse.
   - Creates one `OrderItem` per product, capturing `unit_price` at time of purchase.
   - Decrements each product's inventory in the selected warehouse using **pessimistic locking** (`SELECT ... FOR UPDATE`) to prevent race conditions under concurrent requests.

### Database schema

```
customers
├── id
├── name
├── email          (unique)
└── credit_card_number

products
├── id
├── name
├── sku            (unique)
└── price

warehouses
├── id
├── name
├── address
├── latitude
└── longitude

warehouse_inventories
├── id
├── warehouse_id   (FK → warehouses)
├── product_id     (FK → products)
└── quantity       (unique on [warehouse_id, product_id])

orders
├── id
├── customer_id    (FK → customers)
├── warehouse_id   (FK → warehouses)
├── shipping_address
├── shipping_lat
├── shipping_lng
├── status         (pending | confirmed | failed)
├── total_amount
└── payment_id

order_items
├── id
├── order_id       (FK → orders)
├── product_id     (FK → products)
├── quantity
└── unit_price     (captured at time of purchase)
```

## Running locally

### Prerequisites

- Ruby 4.0.1
- PostgreSQL running locally

### Setup

```bash
# Install dependencies
bundle install

# Create and migrate the database
bin/rails db:create db:migrate

# Seed with sample customers, products, and warehouses
bin/rails db:seed
```

The seed creates:
- 3 customers (Alice, Bob, Carol)
- 5 products (Wireless Headphones, Mechanical Keyboard, USB-C Hub, Webcam HD, Mouse Pad XL)
- 5 warehouses across the US (NYC, LA, Chicago, Houston, Seattle) with varying inventory levels

### Start the server

```bash
bin/rails server
```

The API will be available at `http://localhost:3000`.

### Place an order

```bash
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": 1,
    "shipping_address": "123 Main St, New York, NY 10001",
    "items": [
      { "product_id": 1, "quantity": 2 },
      { "product_id": 2, "quantity": 1 }
    ]
  }'
```

**Successful response (`201 Created`):**

```json
{
  "id": 1,
  "status": "confirmed",
  "warehouse_id": 1,
  "total_amount": "289.97",
  "payment_id": "pay_9b3146c0e8eaabbd2ef3619d",
  "shipping_address": "123 Main St, New York, NY 10001",
  "items": [
    { "product_id": 1, "quantity": 2, "unit_price": "79.99" },
    { "product_id": 2, "quantity": 1, "unit_price": "129.99" }
  ]
}
```

### Error responses

| Status | Cause |
|---|---|
| `400 Bad Request` | Missing required parameters |
| `404 Not Found` | Customer or product does not exist |
| `402 Payment Required` | Payment was declined |
| `422 Unprocessable Entity` | No warehouse can fulfill the order (insufficient stock) |
