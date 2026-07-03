# Estado del Proyecto — Julio 2026

---

## Progreso general

| Área | Estado |
|---|---|
| Roles (buyer vs gallery_admin) | ✅ Completo |
| Auth (JWT, middleware, refresh) | ✅ Completo |
| Artisan CRUD | ✅ Completo |
| Product CRUD | ✅ Completo |
| Upload de imágenes (MinIO) | ✅ Completo |
| Perfil editable (name, wallet) | ✅ Completo |
| Validaciones de formularios | ✅ Completo |
| Comisión por producto | ✅ Completo |
| Buyer Explore + detalle | ✅ Completo |
| Buyer Órdenes | ✅ (si splitter corre) |
| Dashboard admin | ✅ Básico (métricas) |
| Flujo de pago (checkout) | ✅ Funciona en físico, falla en emulador |

---

## Lo que ya funciona — detalle

### Backend (Gallery API `:4000` + Splitter `:4001` + MinIO `:9000`)

**Auth y Roles**
- `POST /api/auth/register` — registra buyer (role=buyer) o admin con `invite_code` + `gallery_name` (crea User + Gallery)
- `POST /api/auth/login` — JWT con claims `sub`, `role`, `gallery_id`
- `GET /api/auth/me` — perfil del usuario + gallery_id
- `PATCH /api/auth/me` — actualizar nombre y wallet
- `AuthRequired` (valida JWT) + `RequireGalleryOwner` (compara `gallery_id` JWT vs URL)
- Una galería por usuario (ADR-0005)

**Artisans** `GET|POST /galleries/:gid/artisans`, `GET|PATCH|DELETE /galleries/:gid/artisans/:id`
- Campos: name, wallet_address_url, image_url, bio, location, specialty, craft_type, tags
- `POST /galleries/:gid/artisans/:id/toggle-active` con `?cascade=true`
- `POST /galleries/:gid/link-artisan/:artisan_id` — asociar existente
- `DELETE /galleries/:gid/link-artisan/:artisan_id` — desasociar
- Delete rechazado si tiene productos (409)
- `GET /api/artisans/:id` público, filtra `is_active=true`

**Products** `GET|POST /galleries/:gid/artisans/:id/products`, `GET|PATCH|DELETE /galleries/:gid/products/:id`
- Campos: name, base_price, asset_code (default USD), asset_scale (default 2), image_url, commission_rate
- Detalle: description, materials, dimensions, tags (tabla `product_details`)
- `POST /galleries/:gid/products/:id/toggle-active`
- Comisión por producto, no por galería
- Imágenes: `GET|POST /galleries/:gid/products/:id/images`, `DELETE .../images/:image_id`
- Límite 5 imágenes por producto

**Upload** `POST /api/upload` (multipart, JWT required)
- Procesa con `imaging` (Go): thumb 200x200 fill JPEG 72%, medium 800px fit JPEG 85%
- Almacena en MinIO, devuelve `{thumbnail_url, medium_url}`
- Image proxy: `GET /products/*filepath` sirve desde MinIO
- Formatos: jpg, jpeg, png, webp, heic

**Dashboard** `GET /galleries/:gid`
- Gallery info + conteos: active/total artisans, active/total products

**Explore** `GET /api/explore/products`, `GET /api/explore/products/:id`
- Filtra `is_active=true` (producto y artesano)
- ProductDetailResponse: split, images, tags, artisan info

### Flutter App

**Navegación**
- Dual-shell: buyer (Explorar, Historial) vs admin (Dashboard, Artesanos, Productos, Ajustes)
- `sessionNotifier` + `refreshListenable` — GoRouter no se recrea
- Login/register → redirect automático según rol
- Logout limpia token, va a login

**Admin — Dashboard**
- Métricas: artesanos activos/total, productos activos/total
- Nombre de galería, pull-to-refresh

**Admin — Artesanos**
- Lista con foto (thumb), nombre, ubicación/especialidad, wallet, toggle
- Crear/editar: form con 8 campos + cámara/galería para foto
- Preview de imagen subida en el form (usa medium URL)
- Toggle con diálogo "cascada" (solo artesano / con productos)
- Eliminar con confirmación
- Vista de productos por artesano, crear producto desde ahí

**Admin — Productos**
- Lista plana con toggle, delete, tap → detalle
- Detalle: imagen principal, precio, comisión, descripción, materiales, dimensiones, tags, galería de imágenes (contador 3/5, add/delete)
- Editar: form con todos los campos + imagen (precarga desde API)
- Refresh post-edit (await push + reload)

**Admin — Ajustes**
- Card de perfil (nombre, email) con tap → cuenta editable
- Botón logout

**Buyer — Explore**
- Grid de productos con foto, nombre, precio, artesano, split
- Búsqueda por texto
- Imágenes con baseUrl prepended (soporta URLs relativas)

**Buyer — Detalle de producto**
- Galería de imágenes (page view), specs, descripción, tags, split, artesano

**Buyer — Cuenta** (`/account`, push)
- Perfil editable: nombre, wallet (modo edición/visualización)
- Logout

**Validaciones**
- Artisan: nombre requerido (min 2 chars), wallet debe empezar con `https://`
- Product: nombre requerido, precio > 0, comisión 0-100
- Imágenes: máximo 5 por producto

---

## Lo que falta

### Prioridad alta
- [ ] **Filtros en Explore** — por ubicación, especialidad, rango de precio
- [ ] **Paginación** en listas (artesanos, productos, explore)
- [ ] **Eliminar foto de artesano** (actualmente solo cambiar)
- [ ] **Ordenar productos** (drag & drop para reordenar)
- [ ] **Buscar artesanos** en el admin
- [ ] **Vista de producto en Explore** — cuando un producto se crea con foto, thumbnail no siempre se ve (URL relativa en algunos contextos)

### Prioridad media
- [ ] **Dashboard avanzado** — pagos completados, ingresos estimados, gráficos
- [ ] **Estadísticas** por artesano, por producto
- [ ] **Notificaciones** (WebSocket) para cambios de estado, pagos
- [ ] **Exportar datos** (CSV)
- [ ] **Dark mode**
- [ ] **Soporte multi-idioma** (es/en)
- [ ] **Eliminación masiva** de productos/artesanos
- [ ] **Mejorar feedback de carga** en uploads (progress bar)

### Prioridad baja / ideas
- [ ] Onboarding para nuevos admins
- [ ] Vista previa del split al crear producto
- [ ] Categorías de productos
- [ ] Productos destacados
- [ ] Auditoría de cambios
- [ ] Tests E2E (Flutter integration tests)
- [ ] CI/CD

### Deuda técnica
- [ ] Splitter callback usa `SPLITTER_PUBLIC_URL` — funciona en físico, falla en emulador
- [ ] `api_client.dart` getter/setter innecesario para token
- [ ] No se valida que artesano pertenezca a la galería al crear producto
- [ ] Tests solo cubren capa de servicio (Go), no handlers HTTP
- [ ] `ProductDetail.tags` cambió de `text[]` a `text` — migración manual en DB existentes

---

## Estructura actual

```
backend/
├── cmd/gallery/main.go          ─ 31 rutas, auth + admin + upload
├── cmd/splitter/main.go         ─ split payment engine
├── cmd/seed/main.go             ─ datos de prueba
├── internal/gallery/
│   ├── config/                  ─ JWT, DB, MinIO, InviteCode, SplitterURL
│   ├── handler/                 ─ auth, artisan, product, gallery, upload, image_proxy, product_image, payment, favorite, checkout, health
│   ├── middleware/               ─ auth, optional_auth, require_gallery_owner
│   ├── model/                   ─ user, gallery, artisan, product, product_detail, product_image, commission, favorite, payment
│   └── service/                 ─ todos los servicios + tests (34 tests)
└── internal/shared/             ─ logging, modelos compartidos, split

app/lib/
├── config/                      ─ app_config, theme
├── models/                      ─ user, session, artisan, admin_product, product, product_detail, gallery_dashboard, checkout, payment
├── providers/                   ─ auth, admin, admin_crud, gallery, checkout, payments, api_client
├── router/                      ─ app_router (dual-shell)
├── screen/
│   ├── admin/
│   │   ├── dashboard/
│   │   ├── artisans/            ─ list, form, products
│   │   ├── products/            ─ list, form, detail
│   │   └── settings/
│   ├── auth/                    ─ login, register
│   ├── explore/                 ─ explore, product_detail
│   ├── orders/
│   ├── checkout/
│   ├── account/
│   └── payment/
├── service/                     ─ api_client, auth, gallery, checkout, ws, logger
└── widgets/                     ─ app_*, product_card, admin_shell, split_bar, status_badge

docs/
├── adr/                         ─ 0001-0005
├── prd/                         ─ 0001-roles, 0001-roles-issues
├── STATUS.md                    ─ este archivo
└── CONTEXT-MAP.md
```

---

## Commits destacados

```
046be7e feat: editable profile (name + wallet)
5c0af30 feat: complete product CRUD (detail fields, images, edit, detail screen)
f53e404 feat: image upload endpoint (resize + MinIO)
7788925 feat: add location, specialty, craft_type, tags to Artisan
71dce36 feat: commission per product
05f3362 fix: ValueNotifier + refreshListenable (GoRouter no recreates)
67836da feat(backend): roles (JWT, nested routes, toggle, dashboard)
7959def feat(app): dual-shell router (buyer vs admin)
a9a0327 docs: roles PRD, ADR-0005, CONTEXT.md, skills
```
