# PRD: Payments History

## Problem Statement

Buyers complete split payments but have no record of what they purchased. Artisans and galleries have no way to see incoming payments. The system needs a persistent transaction log that each user can consult.

## Solution

A `payments` database table that records every split payment. A `GET /api/payments` endpoint that returns transactions filtered by the authenticated user's role (buyer sees purchases, gallery sees incoming). An Orders screen in the app that displays the list with product details, amounts, and status.

## User Stories

1. As a buyer, I want to see a list of my completed purchases, so that I can track what I've bought.
2. As a gallery operator, I want to see incoming payments, so that I can track sales and commissions.
3. As a user, I want to see the date, amount, product, artisan, and status of each transaction.
4. As a system, I want payments to be recorded automatically when the Splitter confirms completion.

## Implementation Decisions

### Database Schema

**`payments`** table:

| Column | Type | Notes |
|--------|------|-------|
| id | PK auto | |
| session_id | string, unique | From Splitter |
| buyer_id | FK → users | The payer |
| product_id | FK → products | |
| artisan_id | FK → artisans | |
| gallery_id | FK → galleries | |
| total_amount | int64 | Smallest unit (cents) |
| asset_code | string | "USD" |
| asset_scale | int | 2 |
| artisan_share | int64 | Amount sent to artisan |
| gallery_share | int64 | Amount sent to gallery |
| status | string | pending / completed / failed |
| completed_at | timestamptz | Null until completed |

### Backend API

**`POST /api/checkout/save`** — Called by the app after checkout init:

Request:
```json
{
  "session_id": "...",
  "product_id": 1,
  "buyer_id": 1,
  "total_amount": 8000,
  "asset_code": "USD",
  "asset_scale": 2,
  "artisan_share": 5600,
  "gallery_share": 2400
}
```

Response: `{ "id": 1, "status": "pending" }`

**`POST /api/checkout/complete`** — Called by Splitter or app after WebSocket confirms:

Request: `{ "session_id": "...", "status": "completed" }`

Response: `{ "status": "completed" }`

**`GET /api/payments`** — Returns payments for the authenticated user:

- If user is a gallery owner → payments where `gallery_id` matches their galleries
- If user is a regular buyer → payments where `buyer_id` = user.id
- Future: if user is an artisan → payments where `artisan_id` matches

Response:
```json
[
  {
    "id": 1,
    "session_id": "abc...",
    "product_name": "Tapete tejido",
    "artisan_name": "Juan López",
    "gallery_name": "Galería Oaxaca",
    "total_amount": 8000,
    "asset_code": "USD",
    "asset_scale": 2,
    "artisan_share": 5600,
    "gallery_share": 2400,
    "status": "completed",
    "completed_at": "2026-06-20T23:41:00Z"
  }
]
```

### Frontend

**Model:** `Payment` class with `fromJson`.

**Service:** `getPayments()` in `GalleryService`.

**Provider:** `paymentsProvider` — `FutureProvider<List<Payment>>`.

**Screen:** `OrdersScreen` — already exists as a shell. Replace with:

- Loading spinner
- Error state
- Empty state: "No transactions yet"
- `ListView` of payment cards
- Each card shows: product name, artisan, amount, date, status badge
- Optional: tab bar for "Purchases" vs "Sales" (future)

**Checkout flow update:**
- After WebSocket confirms completed, call `POST /api/checkout/complete` (or `save` on init + `complete` on finish).

## Seams

1. **Model** — `Payment` in `backend/internal/gallery/model/payment.go`
2. **Service** — `PaymentService` (not to be confused with Splitter's PaymentService) with `Save`, `Complete`, `ListByUser`
3. **Handler** — handlers for save/complete/list
4. **Routes** — register in `main.go`
5. **Frontend model** — `Payment` in `lib/models/payment.dart`
6. **Frontend service** — `getPayments()` method
7. **Frontend provider** — `paymentsProvider`
8. **Screen** — upgrade `OrdersScreen`

## Out of Scope

- Push notifications (FCM) — tracked separately
- Artisan login (future role system)
- Refunds / cancellations
- Pagination (v1 returns all, paginate when > 50)
- Filtering by date range

## Further Notes

- `buyer_id` is the `User` who initiated the checkout (the logged-in user).
- For now, only `buyer_id` is used to filter. Gallery filter is ready but gallery operators need a dashboard screen.
- The product/artisan/gallery names are stored in the payments table via JOIN at query time, not denormalized.
- The `session_id` from the Splitter is the unique key that lets us match the WebSocket confirmation to the saved payment.
