# Issues: Roles y Control de Acceso

Parent: [PRD 0001 - Roles](./0001-roles.md)

> **Status**: BACKEND COMPLETO (B1-B4) | FRONTEND PENDIENTE (F1-F3)

---

## BACKEND ✅

### B1: Schema + JWT: Role, IsActive, claims en token

**Acceptance criteria**:
- [x] `User` tiene campo `Role string` con valores `"buyer"` o `"gallery_admin"`
- [x] `Artisan` y `Product` tienen campo `IsActive bool` (default `true`)
- [x] `POST /auth/login` devuelve JWT con claims `sub`, `role`, `gallery_id` (si admin)
- [x] `POST /auth/register` (buyer) devuelve JWT con claims `sub`, `role: "buyer"` sin `gallery_id`
- [x] `ValidateToken` extrae `role` y `gallery_id` del token e inyecta en contexto gin
- [x] `POST /galleries` emite nuevo JWT con `gallery_id` incluido

---

### B2: Middleware RequireGalleryOwner + migración de rutas anidadas

**Acceptance criteria**:
- [x] `RequireGalleryOwner` middleware: extrae `:gallery_id` de URL, compara con claim del JWT, 403 si no coinciden
- [x] Grupo de rutas admin usa `AuthRequired` + `RequireGalleryOwner` encadenados
- [x] `POST /api/artisans` → `POST /api/galleries/:gid/artisans` (crea + asocia automáticamente)
- [x] `POST /api/artisans/:id/products` → `POST /api/galleries/:gid/artisans/:id/products`
- [x] `DELETE /api/products/:id` → `DELETE /api/galleries/:gid/products/:id`
- [x] `PATCH /api/galleries/:gid/artisans/:id` — update artisan (name, wallet, bio, image)
- [x] `DELETE /api/galleries/:gid/artisans/:id` — delete artisan (rechaza si tiene productos, 409)
- [x] `PATCH /api/galleries/:gid/products/:id` — update product (name, base_price, image)
- [x] `GET /api/galleries/:gid/artisans` — lista artesanos de la galería (admin ve todo)
- [x] `GET /api/galleries/:gid/products` — lista todos los productos de la galería (admin ve todo)
- [x] `GET /api/galleries/:gid/artisans/:id/products` — productos de un artesano específico
- [x] `GET /api/artisans/:id` se vuelve público y filtra `is_active=true` (404 si inactivo)
- [x] Rutas planas antiguas eliminadas del router

**Blocked by**: B1

---

### B3: Toggle endpoints + filtro is_active en rutas públicas + delete protection

**Acceptance criteria**:
- [x] `POST /api/galleries/:gid/artisans/:id/toggle-active` — invierte `is_active`
- [x] `POST /api/galleries/:gid/products/:id/toggle-active` — invierte `is_active`
- [x] `?cascade=true` en toggle de artesano aplica toggle a todos sus productos
- [x] `GET /api/explore/products` filtra productos con `is_active=true` y artesano `is_active=true`
- [x] `GET /api/explore/products/:id` devuelve 404 si producto o artesano inactivos
- [x] `GET /api/artisans/:id` devuelve 404 si inactivo
- [x] `DELETE /api/galleries/:gid/artisans/:id` devuelve 409 si el artesano tiene productos

**Blocked by**: B2

---

### B4: Admin registration con invite_code + dashboard endpoint

**Acceptance criteria**:
- [x] `POST /auth/register` con `role: "gallery_admin"` requiere `invite_code` que matchee env var
- [x] Admin registration crea User (role=gallery_admin) + Gallery (nombre provisto) en una transacción
- [x] Devuelve JWT con `role` y `gallery_id`
- [x] Sin `invite_code` o inválido → 403
- [x] `GET /api/galleries/:gid` devuelve nombre, commission rate, conteo de artesanos, conteo de productos

**Blocked by**: B1

---

## FRONTEND

### F1: Modelos (role, galleryId) + auth provider + router dual-shell

**Qué construir**: Agregar `role` y `galleryId` a `Session` y `User`. Actualizar `authProvider` para parsear los claims del JWT. Modificar `appRouter` con dos `ShellRoute` condicionales (buyer vs admin). El redirect decide cuál aplicar según `role`.

**Acceptance criteria**:
- [ ] `User.fromJson` parsea campo `role`
- [ ] `Session.fromJson` parsea `role` y `gallery_id`
- [ ] `authProvider.build()` extrae claims del token y puebla `Session` con role/galleryId
- [ ] `appRouter` tiene dos `ShellRoute`: buyer (Explorar, Historial) y admin (placeholders)
- [ ] Redirect: `role == "gallery_admin"` → `/admin/dashboard`, `role == "buyer"` → `/explorar`
- [ ] Login/register redirige al shell correcto según role
- [ ] Logout limpia token y redirige a `/login`

**Blocked by**: B1

---

### F2: Admin: Dashboard + Commission Settings

**Qué construir**: Pantalla Dashboard (métricas básicas: nombre galería, commission rate, conteo artesanos, conteo productos). Pantalla Commission Settings (slider o input para rate, llama a `PUT /galleries/:gid/commission`).

**Acceptance criteria**:
- [ ] `GET /api/galleries/:gid` al entrar al dashboard, muestra nombre, rate, conteos
- [ ] Loading/error states para dashboard
- [ ] Commission Settings: muestra rate actual, permite editar y guardar
- [ ] `PUT /api/galleries/:gid/commission` con feedback de éxito/error
- [ ] Navegación: Dashboard y Settings como tabs del admin shell

**Blocked by**: B1, F1

---

### F3: Admin: Artisan Directory + Product Directory + CRUD + toggle

**Qué construir**: Pantallas de Artisan Directory (lista, crear, editar, toggle, delete) y Product Directory (lista, crear, editar desde detalle de artesano, toggle, delete). Toggle con opción de cascada en artesano. Productos visibles desde detalle de artesano y desde tab propia.

**Acceptance criteria**:
- [ ] Artisan Directory: lista de artesanos con toggle switch visible, fab para crear
- [ ] Crear artesano: form con name, wallet, bio, image
- [ ] Editar artesano: mismo form precargado
- [ ] Toggle artesano: switch que llama `POST .../toggle-active`, con opción "aplicar a productos"
- [ ] Delete artesano: confirm dialog, muestra error si tiene productos (409)
- [ ] Product Directory: lista plana de todos los productos, toggle switch, filtro por artesano (opcional)
- [ ] Detalle de artesano: muestra sus productos, crear nuevo desde ahí
- [ ] Crear/editar producto: form con name, base_price, asset_code, image
- [ ] Toggle producto: switch que llama `POST .../toggle-active`
- [ ] Delete producto: confirm dialog + llamado DELETE
- [ ] Inactivos se muestran con indicador visual (gris, tachado, etc.)
- [ ] Pull-to-refresh en listas

**Blocked by**: B2, B3, F1

---

## Orden de implementación

```
B1 ──→ B2 ──→ B3
  │               │
  └──→ B4        │
  │               │
  └──→ F1 ──→ F2 │
          │       │
          └──→ F3 ←┘
```
