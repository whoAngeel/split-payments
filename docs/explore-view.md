# Explore View — Design Prompt for Design Agent

Use this prompt to generate or refine the **Explore (Discover)** view of the Oaxaca Artisan marketplace app.

## Context

A split-payment marketplace where users discover handcrafted Oaxacan works (textiles, pottery, jewelry, wood carving). Each product card shows a **split payment breakdown** (artisan / gallery / platform commission) and a **Buy with Open Payments** CTA.

## Brand Identity

- **Terracotta & Cream palette** — warm earth tones, high-end editorial feel
- **Dual typography:** `Playfair Display` for headings (serif, sophisticated), `Inter` for body (clean, modern)
- **Texture overlay** — canvas/orange grain + subtle white feathers for a tactile, handcrafted feel
- **Shadows** — warm terracotta-toned shadows (`rgba(151, 49, 0, 0.15)`)
- **Border radius** — `xl` (`12px`) for cards, `full` for pills/chips

## Layout Structure

1. **TopAppBar** — fixed, bg-surface, shadow
   - Hamburger menu (left)
   - Logo: "OAXACA ARTISAN" in `headline-md`
   - User avatar (right, circular)
2. **Hero Section: Featured Artisan**
   - Card with backdrop blur + terracotta shadow
   - Left: square artisan portrait (aspect-ratio 1:1)
   - Right: "Featured Artisan" pill badge, artisan name (`headline-lg`), italic quote, "View Artisan Bio" CTA button
   - Subtle parallax on scroll (`translateY(scroll * 0.05)`)
3. **Search & Filter Bar**
   - Full-width search input with leading search icon, bottom-border style
   - Horizontally scrollable category pills: All Works, Textiles, Pottery, Jewelry, Wood Carving
   - Thin custom scrollbar
4. **Product Grid**
   - Responsive: `1 col` mobile → `2 col` tablet → `3 col` desktop
   - Gap: `gutter` (`16px`)
5. **BottomNavBar** — fixed bottom, backdrop-blur, 3 tabs
   - **Discover** (active, filled icon) | Wallet | Profile

## Product Card Spec (critical)

Each card is a flex column with:

- **Image** — aspect-ratio 4:5, `object-cover`, zoom on hover (scale 1.05, 500ms)
- **Favorite button** — absolute top-right, white/80 backdrop, heart icon, hover fill
- **Content area:**
  - Title (`headline-md`), artisan name (`body-sm`), price (`headline-md` in primary)
  - **Split Payment Visualizer** (key differentiator):
    - Label line: "Split Payment Breakdown" | "85% to Artisan"
    - Thin progress bar (h-1.5, rounded-full): colored segments for each split party
    - Legend chips: small colored dots with labels (Artisan, Gallery, Platform)
  - **"Buy with Open Payments" button** — full-width, `primary-container` bg, pill style

## Color Tokens

Use these exact Material Design 3–style tokens extracted from the design:

| Token | Hex |
|---|---|
| `primary` | `#973100` |
| `primary-container` | `#c04000` |
| `on-primary-container` | `#ffe9e3` |
| `primary-fixed` | `#ffdbcf` |
| `primary-fixed-dim` | `#ffb59b` |
| `on-primary-fixed` | `#380d00` |
| `on-primary-fixed-variant` | `#812800` |
| `secondary` | `#4e6074` |
| `secondary-container` | `#cee1fa` |
| `on-secondary-container` | `#526479` |
| `secondary-fixed` | `#d1e4fc` |
| `secondary-fixed-dim` | `#b5c8e0` |
| `on-secondary-fixed` | `#091d2e` |
| `on-secondary-fixed-variant` | `#36485c` |
| `tertiary` | `#006036` |
| `tertiary-container` | `#187b49` |
| `on-tertiary-container` | `#b3ffc9` |
| `tertiary-fixed` | `#9af6b8` |
| `tertiary-fixed-dim` | `#7ed99e` |
| `on-tertiary-fixed` | `#00210f` |
| `on-tertiary-fixed-variant` | `#00522d` |
| `background` | `#fefccf` |
| `surface` | `#fefccf` |
| `surface-dim` | `#dedcb1` |
| `surface-bright` | `#fefccf` |
| `surface-container` | `#f2f0c4` |
| `surface-container-low` | `#f8f6c9` |
| `surface-container-high` | `#eceabe` |
| `surface-container-highest` | `#e6e5b9` |
| `surface-container-lowest` | `#ffffff` |
| `surface-variant` | `#e6e5b9` |
| `on-surface` | `#1d1d03` |
| `on-surface-variant` | `#594139` |
| `outline` | `#8d7167` |
| `outline-variant` | `#e1bfb4` |
| `error` | `#ba1a1a` |
| `error-container` | `#ffdad6` |
| `inverse-surface` | `#323214` |
| `inverse-on-surface` | `#f5f3c7` |
| `inverse-primary` | `#ffb59b` |

## Typography System

| Token | Font | Size | Weight | Line Height |
|---|---|---|---|---|
| `display` | Playfair Display | 48px | 700 | 56px, -0.02em letter-spacing |
| `headline-lg` | Playfair Display | 32px | 700 | 40px |
| `headline-lg-mobile` | Playfair Display | 28px | 700 | 36px |
| `headline-md` | Playfair Display | 24px | 600 | 32px |
| `body-lg` | Inter | 18px | 400 | 28px |
| `body-md` | Inter | 16px | 400 | 24px |
| `body-sm` | Inter | 14px | 400 | 20px |
| `label-caps` | Inter | 12px | 600 | 16px, 0.08em letter-spacing |
| `mono-tech` | Inter | 13px | 500 | 18px, 0.02em letter-spacing |

## Spacing Tokens

| Token | Value |
|---|---|
| `xs` | 4px |
| `base` | 8px |
| `sm` | 12px |
| `gutter` | 16px |
| `container-margin` | 20px |
| `md` | 24px |
| `lg` | 40px |
| `xl` | 64px |

## Interaction Notes

- Buttons/links: `active:scale-95` + `duration-150` for tactile feedback
- Heart icon: white/80 bg → `primary` bg on hover, icon toggles fill via `font-variation-settings`
- Category pills: `active:scale-95`; active state uses `secondary-container`
- Hero parallax: `translateY(scroll * 0.05)` — subtle, keep below 0.1
- Product image: zoom on group-hover, 500ms ease
- Search input: bottom-border style, focus transitions to `primary` color

## States & Edge Cases

The implementation must handle:

1. **Loading** — skeleton placeholders for product grid (aspect-ratio 4:5 grey blocks with shimmer)
2. **Empty** — "No artworks found" illustration with search terms highlighted when filters yield 0 results
3. **Error** — inline error banner if featured artisan fails to load; toast for buy failures
4. **Offline** — cached product grid with "You're offline" banner at top; buy button disabled with tooltip
5. **Long titles** — truncate to 2 lines with ellipsis; artisan name always visible
6. **Many categories** — horizontal scroll with fade edges; "All Works" always pinned first
7. **Bottom nav safe area** — respect `pb-safe` for devices with home indicator
8. **Keyboard** — search field must not be hidden by keyboard on mobile; viewport scrolls to keep it visible
9. **Dynamic split values** — progress bar segments must handle 1, 2, or 3 parties; percentages must sum to 100
10. **RTL** — layout must mirror for Spanish/Arabic locales (likely out of scope for v1 but consider)

## Generation Instructions for the Agent

Take the provided HTML/CSS reference and generate a **Flutter widget** or **React component** (depending on project stack) that reproduces this explore view pixel-perfectly. Use the exact color tokens, typography scale, and spacing tokens above. The split payment visualizer is the core differentiator — make it prominent and animated (subtle width transition on load). All interactive states must be implemented. Handle loading, empty, error, and offline states.

If generating for Flutter:
- Use `Material 3` theming with custom `ColorScheme.fromSeed`
- Product grid: `SliverGrid` with `delegate: SliverChildBuilderDelegate`
- Category pills: horizontal `ListView`
- Hero parallax: `NotificationListener<ScrollUpdateNotification>`

If generating for React:
- Use Tailwind CSS with the custom config above
- Product grid: CSS Grid with responsive breakpoints
- Skeleton: `tailwindcss-animate` for shimmer
- Hero parallax: `useScroll` from framer-motion or raw `scroll` event

---

## API Contract — Backend Endpoints

The frontend consumes the following endpoints from the Gallery API (`localhost:4000`):

### `GET /api/explore/products`

Returns the product feed for the Discover tab. Accepts optional JWT via `Authorization: Bearer <token>`.

**Auth:** Optional — if a valid JWT is sent, `is_favorited` is populated per product.

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "Sky & Earth Rug",
    "base_price": 42000,
    "asset_code": "USD",
    "asset_scale": 2,
    "artisan_name": "Elena Velasco",
    "image_url": "https://...",
    "split": {
      "artisan_percent": 70,
      "gallery_percent": 30,
      "platform_percent": 0
    },
    "is_favorited": false
  }
]
```

**Frontend notes:**
- `base_price` is in the smallest unit (e.g., cents). Divide by `10^asset_scale` for display: `price = base_price / pow(10, asset_scale)`. E.g., `42000` with `asset_scale=2` = `$420.00`.
- `split` is `null` if the product's artisan has no gallery/commission configured. Hide the split visualizer in that case.
- `is_favorited` is always `false` for unauthenticated users. For authenticated users, it reflects actual state.
- Heart icon state: if `is_favorited === true`, render filled heart. On tap, call `POST /api/favorites/:product_id`.

### `POST /api/favorites/:product_id`

**Auth:** Required (JWT).

**Request:** Empty body.

**Response (200):**
```json
{
  "is_favorited": true
}
```

`is_favorited` indicates the new state: `true` = added, `false` = removed. This is a **toggle** — same endpoint for add and remove.

**Frontend notes:**
- On heart tap, send POST and update local state with the response `is_favorited`.
- Optimistic UI is safe: the toggle is idempotent and fast.

### `GET /api/favorites`

Returns all favorited products for the current user.

**Auth:** Required (JWT).

**Response (200):**
```json
[
  {
    "id": 1,
    "user_id": 1,
    "product_id": 5,
    "product": { ... }
  }
]
```

Useful for the Profile > Favorites section.

### Price Display Helper

```ts
function formatPrice(basePrice: number, scale: number, code: string): string {
  const amount = basePrice / Math.pow(10, scale);
  return `${code} ${amount.toFixed(scale)}`;
  // e.g., formatPrice(42000, 2, "USD") => "USD 420.00"
}
```

### Split Visualizer Render Logic

```ts
function renderSplitBar(split: ProductSplit | null) {
  if (!split) return null; // hide visualizer
  const total = split.artisan_percent + split.gallery_percent + split.platform_percent;
  // total should always be 100
  return (
    <div class="split-bar">
      <div style={{ width: split.artisan_percent + '%' }} class="segment artisan" />
      <div style={{ width: split.gallery_percent + '%' }} class="segment gallery" />
      <div style={{ width: split.platform_percent + '%' }} class="segment platform" />
    </div>
  );
}
```
