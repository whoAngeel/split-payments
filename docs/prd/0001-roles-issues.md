# Issues: Roles y Control de Acceso

Parent: [PRD 0001 - Roles](./0001-roles.md)

> **Status**: COMPLETO ✅ — Backend B1-B4 + Frontend F1-F3

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

---

### B4: Admin registration con invite_code + dashboard endpoint

**Acceptance criteria**:
- [x] `POST /auth/register` con `role: "gallery_admin"` requiere `invite_code` que matchee env var
- [x] Admin registration crea User (role=gallery_admin) + Gallery (nombre provisto) en una transacción
- [x] Devuelve JWT con `role` y `gallery_id`
- [x] Sin `invite_code` o inválido → 403
- [x] `GET /api/galleries/:gid` devuelve nombre, commission rate, conteo de artesanos, conteo de productos

---

## FRONTEND ✅

### F1: Modelos (role, galleryId) + auth provider + router dual-shell

**Acceptance criteria**:
- [x] `User.fromJson` parsea campo `role`, `isAdmin` getter
- [x] `Session.fromJson` parsea `role` y `gallery_id`
- [x] `authProvider.build()` obtiene `me()` que devuelve Session con role/galleryId
- [x] `appRouter` tiene dos `ShellRoute`: buyer (Explorar, Historial) y admin (Dashboard, Artesanos, Productos, Ajustes)
- [x] Redirect: `role == "gallery_admin"` → `/admin/dashboard`, `role == "buyer"` → `/explorar`
- [x] Login/register redirige al shell correcto según role
- [x] Logout limpia token y redirige a `/login`

---

### F2: Admin: Dashboard + Commission Settings

**Acceptance criteria**:
- [x] `GET /api/galleries/:gid` al entrar al dashboard, muestra nombre, rate, conteos activos/total
- [x] Loading/error states para dashboard (CircularProgressIndicator / AppErrorState)
- [x] Commission Settings: input numérico para %, botón Guardar
- [x] `PUT /api/galleries/:gid/commission` con feedback de éxito/error
- [x] Navegación: Dashboard y Settings como tabs del admin shell

---

### F3: Admin: Artisan Directory + Product Directory + CRUD + toggle

**Acceptance criteria**:
- [x] Artisan Directory: lista con toggle switch, FAB para crear
- [x] Crear artesano: form con name, wallet (push route `/admin/artisans/new`)
- [x] Editar artesano: mismo form precargado (`/admin/artisans/:id/edit`)
- [x] Toggle artesano: switch con dialog "cascada" (aplicar a productos o solo artesano)
- [x] Delete artesano: confirm dialog con AlertDialog
- [x] Product Directory: lista plana de todos los productos, toggle switch, delete
- [x] Detalle de artesano: `/admin/artisans/:id/products` muestra sus productos + FAB crear
- [x] Crear producto: desde detalle de artesano (`/admin/artisans/:id/products/new`)
- [x] Toggle producto: switch que llama `POST .../toggle-active`
- [x] Delete producto: confirm dialog + llamado DELETE
- [x] Inactivos se muestran con color atenuado (surfaceContainerHighest)
- [x] Pull-to-refresh en listas

**Notas de implementación**:
- Editar producto: no implementado (pendiente, no bloqueante). Se puede agregar como push route.
- Product form: solo accesible desde detalle de artesano, no desde la tab Productos (se necesitaría selector de artesano).
- Link/unlink de artesanos entre galerías movido a `/galleries/:gid/link-artisan/:artisan_id` para evitar conflicto de wildcards en Gin.

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

## Commits

```
245f969 feat(app): F3 - admin artisan & product CRUD with toggle, cascade, delete protection
6fc0750 feat(app): F2 - admin dashboard with metrics, commission settings UI
7959def feat(app): dual-shell router (buyer vs admin), role from JWT, admin placeholder screens
67836da feat(backend): roles - JWT with role+gallery_id, nested admin routes, toggle active, dashboard
a9a0327 docs: roles PRD, ADR-0005 single gallery, CONTEXT.md updates, mattpocock skills
```
