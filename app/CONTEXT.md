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

### Gallery Operator Flow

**Dashboard**:
The gallery operator's home view showing key metrics: active artisans, pending settlements, recent split payments.
_Avoid_: Home, landing

**Artisan Registry**:
The list of artisans registered with the gallery, each with their wallet address and base price for products.
_Avoid_: Seller list, merchant list

**Commission Settings**:
The gallery's commission rate configuration, applied to all artisan base prices in that gallery.
_Avoid_: Fee config, gallery cut
