# App

Flutter mobile application for the OpenPayments Splitter platform. Two primary user personas: buyer (makes split payments) and gallery operator (manages artisans, products, commissions).

## Language

### Buyer Flow

**Checkout**:
The moment a buyer confirms purchase. The App initiates a split payment via the Gallery API, then opens a browser session for GNAP consent at the buyer's wallet provider.
_Avoid_: Payment screen, purchase flow

**Consent Session**:
The in-app browser session where the buyer explicitly approves the outgoing payment(s) at their wallet provider. Managed via `ASWebAuthenticationSession` (iOS) or Chrome Custom Tabs (Android).
_Avoid_: Auth flow, login redirect

**Payment Confirmation**:
The final screen shown after the Splitter completes all outgoing payments. Received via WebSocket or push notification.
_Avoid_: Success screen, receipt

### Roles

**Buyer**:
A user who explores and purchases products. Sees the Explore and Order History tabs. Registers from the app.
_Avoid_: Customer, user

**Gallery Admin**:
A user who owns a gallery. Sees the admin shell with Dashboard, Artisans, Products, and Settings tabs. Created via backend endpoints, not from the app registration flow.

### Admin Shell Tabs

**Dashboard**:
The gallery admin's home view showing key metrics: active artisans, product count, commission rate, recent split payments.
_Avoid_: Home, landing

**Artisan Directory**:
The list of artisans belonging to the gallery. Supports create, edit, delete, and toggle active status. Tapping an artisan shows their products.
_Avoid_: Seller list, merchant list, artisan registry

**Product Directory**:
A flat list of all products in the gallery, regardless of artisan. Supports toggle active status and navigation to product detail. Products can also be managed from within an artisan's detail view.
_Avoid_: Catalog, inventory

**Commission Settings**:
The gallery's commission rate configuration, applied to all artisan base prices in that gallery.
_Avoid_: Fee config, gallery cut
