# Context Map

## Contexts

- [App](./app/CONTEXT.md) — Flutter mobile application. Handles buyer payment flow (wallet login, GNAP redirect consent, payment confirmation), gallery UX (products, artisans, commission settings), and receives push notifications + WebSocket status updates.
- [Gallery](./backend/gallery/CONTEXT.md) — Go API. Manages artisans, products, commissions, and the buyer-facing payment UX. Calculates split shares and delegates payment execution to the Splitter.
- [Splitter](./backend/splitter/CONTEXT.md) — Go API. Generic split-payment engine. Receives split instructions, orchestrates Open Payments grants, quotes, and outgoing payments. Has no domain knowledge about galleries, products, or commissions.

## Relationships

- **App → Gallery**: App calls Gallery API for products, artisans, commission settings, and initiates split payment flows.
- **Gallery → Splitter**: Gallery calls `POST /split` with shares already calculated. Splitter handles all Open Payments interaction and returns status.
- **Splitter → App**: Splitter pushes payment status updates via WebSocket and push notifications. App consumes these to show payment progress and completion.
- **Gallery → App**: Gallery API can also trigger push notifications for non-payment events.

## Repository Structure

```
openpayments/
├── backend/                  # Go monorepo
│   ├── go.mod
│   ├── cmd/
│   │   ├── gallery/main.go
│   │   └── splitter/main.go
│   ├── internal/
│   │   ├── gallery/
│   │   ├── splitter/
│   │   └── shared/
│   ├── gallery/CONTEXT.md
│   └── splitter/CONTEXT.md
├── app/                      # Flutter
│   ├── pubspec.yaml
│   ├── lib/
│   └── CONTEXT.md
├── CONTEXT-MAP.md
└── docs/adr/
```
