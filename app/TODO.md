# TODO App

## Login

- [x] **Mostrar errores de login**
- [x] **Toggle show/hide password**
- [x] **Register** — conectar endpoint de registro

## Navegación

- [x] **Auth guard en router**
- [x] **Logout** — botón en AccountScreen
- [x] **Persistir user en sesión**

## Productos → Explore

- [x] **Endpoint `/api/explore/products`**
- [x] **ExploreScreen con header, búsqueda, grid 1 columna**
- [x] **ProductCard con split visualizer + heart + botón Buy**
- [ ] **Favoritos** — conectar heart a `POST /api/favorites/:id`
- [ ] **Búsqueda real** — conectar search input al endpoint

## Checkout

- [x] **1. Modelos** — `CheckoutRequest` + `CheckoutResponse`
- [x] **2. Service** — `POST /api/checkout`
- [x] **3. Provider** — estado del checkout
- [x] **4. ProductCard onTap** — navega a checkout
- [x] **5. CheckoutScreen UI** — producto, breakdown, wallet input, botón
- [x] **6. Consentimiento** — `launchUrl` + deep link + WebSocket
- [x] **7. PaymentConfirmationScreen** — estado pending/completed

## UX / UI

- [x] **Loading/error states** en ExploreScreen
- [ ] **Pull-to-refresh** en lista de productos
- [ ] **Empty state** cuando no hay productos

## Operator (galería)

- [ ] **Dashboard** — métricas, pagos recientes
- [ ] **Commission settings** — configurar comisión desde la app
