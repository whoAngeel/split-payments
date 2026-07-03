# PRD: Product Detail View

## Problem Statement

Buyers browse products in the Explore view, but the product card doesn't show enough information to make a purchase decision. Buyers need to see materials, dimensions, multiple photos, artisan background, and a detailed description before committing to buy.

## Solution

A new **Product Detail** screen reachable by tapping any product card. It fetches full product metadata from `GET /api/explore/products/:id` and presents a rich scrollable layout: image gallery, price + split breakdown, tags, materials, dimensions, description, a "The Maker" section, and a sticky Buy button.

## User Stories

1. As a buyer, I want to tap a product card and see full product details, so that I can make an informed purchase.
2. As a buyer, I want to swipe through multiple product images, so that I can see the item from different angles.
3. As a buyer, I want to see tags (materials, craft type), so that I can quickly understand what the item is made of.
4. As a buyer, I want to see dimensions and description, so that I know the size and story behind the piece.
5. As a buyer, I want to see a "The Maker" section with the artisan's name, photo, and bio, so that I can connect with the craftsperson.
6. As a buyer, I want a prominent "Buy with Open Payments" button at the bottom, so that I can proceed to checkout without scrolling back up.
7. As a buyer, I want the product name and price visible at all times while scrolling the detail.
8. As an unauthenticated visitor, I want to browse the product detail without being forced to log in.

## Implementation Decisions

### Backend: Database Schema Changes

- **`product_details`** table — 1:1 with `products`:
  - `product_id` (PK, FK → products)
  - `description` (text)
  - `materials` (text)
  - `dimensions` (text)
  - `tags` (text[])

- **`product_images`** table — 1:N with `products`:
  - `id` (PK)
  - `product_id` (FK → products)
  - `image_url` (text, not null)
  - `sort_order` (int, default 0)

- **`artisans`** table — add columns:
  - `image_url` (text)
  - `bio` (text)

### Backend: API Contract

**`GET /api/explore/products/:id`** — Public. Returns:

```json
{
  "id": 1,
  "name": "Tapete tejido",
  "base_price": 8000,
  "asset_code": "USD",
  "asset_scale": 2,
  "description": "Tapete tejido a mano...",
  "materials": "Lana de oveja, tintes naturales",
  "dimensions": "120cm x 180cm",
  "tags": ["Textil", "Hecho a mano", "Lana"],
  "images": ["url1", "url2"],
  "image_url": "url1",
  "artisan": {
    "id": 2,
    "name": "Juan López",
    "image_url": "https://...",
    "bio": "Artesano oaxaqueño...",
    "wallet_address_url": "https://..."
  },
  "split": {
    "artisan_percent": 70,
    "gallery_percent": 30,
    "platform_percent": 0
  }
}
```

### Frontend: Navigation & Routing

- New route `/product/:id` — top-level (outside ShellRoute), uses `push()`.
- Tapping a `ProductCard` navigates to `/product/:id` instead of directly to `/checkout`.
- The `ProductDetailScreen` receives the `productId` from the route param, fetches data.
- A "Buy" button navigates to `/checkout` (sets `selectedProduct`).

### Frontend: Screen Layout (top to bottom)

```
[SliverAppBar with large title + back]
[Image Gallery — PageView/PageController, dots indicator]
[Name + Price]
[Tags — horizontal Wrap of Chips]
[Materials | Dimensions — labeled rows]
[Description — paragraph]
----- Section Header: "The Maker" -----
[Artisan photo (circle) + name]
[Bio text]
[Button: "View Artisan Bio" (future)]
[Sticky Bottom Button: "Buy with Open Payments"]
```

### Seams

1. **API service layer** — `GalleryService.getProductDetail(id)` — new method.
2. **Model** — `ProductDetail` new model extending `Product` with extra fields + `ArtisanProfile`.
3. **Provider** — `productDetailProvider` — family provider keyed by `productId`.
4. **Screen** — `ProductDetailScreen` — new widget, stateful, calls provider.
5. **Router** — new route `/product/:id`.

## Testing Decisions

- Test at the widget level: `ProductDetailScreen` renders all sections with mock data.
- Test error state: API failure shows error message with retry.
- Test loading state: skeleton shimmer for image + text blocks.
- Prefer golden tests for the layout since it's visual-heavy.

## Out of Scope

- Artisan profile page (future: "View full profile" navigates to a separate screen).
- Zoom on images (pinch-to-zoom, future enhancement).
- Related products / "You may also like" section.
- Ratings and reviews.

## Further Notes

- The `Product` model in Flutter needs to be extended or a separate `ProductDetail` model created, to avoid bloating the list model.
- Tags are flat strings for v1; no tag taxonomy system yet.
- Artisan bio is plain text for v1; no rich text or markdown.
