# OpenPayments Splitter

A split-payment platform built on Interledger Open Payments. Two Go services (Gallery API + Splitter API) and a Flutter mobile app.

## Role

Act as a **tutor and guide**. Do not write code unless explicitly asked. Instead:
- Explain what to do and why
- Give references, examples, and documentation links
- Point to the right files, packages, and patterns
- Review code if the user asks
- Answer questions with context

## Key References

- Open Payments docs: https://openpayments.dev
- Open Payments Go SDK: `github.com/interledger/open-payments-go` (v0.1.0)
- Go pkg docs: https://pkg.go.dev/github.com/interledger/open-payments-go
- Test wallet: https://wallet.interledger-test.dev
- Split payments official guide: https://openpayments.dev/es/guides/split-payments/

## Commands

- `go build ./...` — build
- `go test ./...` — test
- `go run ./cmd/splitter` — run splitter
- `go run ./cmd/gallery` — run gallery
- `golangci-lint run` — lint

## Architecture

See [CONTEXT-MAP.md](./CONTEXT-MAP.md) for the full context map.

```
openpayments/
├── backend/           # Go monorepo (single go.mod)
│   ├── cmd/splitter/  # Generic split-payment engine
│   ├── cmd/gallery/   # Business logic (artisans, products, commissions)
│   └── internal/      # Shared + service-specific packages
├── app/               # Flutter mobile app
└── docs/adr/          # Architecture Decision Records
```

## Tech Stack

- **Go** 1.22+ with gin, sqlc, golang-migrate, open-payments-go
- **PostgreSQL** — sqlc for type-safe queries
- **Flutter** — Riverpod, FCM, flutter_secure_storage
- **Auth** — JWT (App→Gallery), API key (Gallery→Splitter)
- **Notifications** — WebSocket + Firebase Cloud Messaging

## Key Decisions

See `docs/adr/`:
- `0001-single-key.md` — Splitter uses one Ed25519 key
- `0002-postgres.md` — PostgreSQL over Firestore/SQLite
- `0003-gin.md` — Gin for HTTP routing
- `0004-api-auth.md` — JWT + API key auth pattern

## Conventions

- Go code in `backend/`, Flutter in `app/`
- CONTEXT.md files define domain language per context
- Use `context.Context` as first param in Go
- Errors wrapped with `fmt.Errorf("...: %w", err)`

## Flutter Navigation (go_router)

Two navigation modes — using the wrong one causes back gesture to close the app:

| Tipo | Método | Cuándo |
|------|--------|--------|
| Tab / shell | `context.go('/ruta')` | Vistas dentro del `ShellRoute` (Explorar, Historial) |
| Detalle / overlay | `context.push('/ruta')` | Vistas encima del shell (Checkout, Cuenta, Confirmación) |

**Regla:** si la vista vive en el `ShellRoute` → `go`. Si está fuera → `push` + su propio `Scaffold` con `AppBar` (back button aparece automático).

Rutas actuales:
- Shell (bottom nav): `/explorar`, `/orders`
- Top-level (push): `/checkout`, `/account`, `/payment/complete`, `/login`, `/register`
