# PRD: Roles y Control de Acceso

## Problem Statement

Actualmente cualquier usuario autenticado puede crear artesanos, productos, y modificar comisiones. No hay distinción entre compradores (buyers) y operadores de galería (gallery admins). Se necesita un sistema de roles que restrinja operaciones administrativas y permita activar/desactivar artesanos y productos.

## Solution

Dos roles: **buyer** (comprador, explora y compra) y **gallery_admin** (gestiona su galería: artesanos, productos, comisión). El rol se asigna al registro y se transporta en el JWT. Las rutas administrativas se anidan bajo `/galleries/:gallery_id` con un middleware de autorización que verifica ownership. Artesanos y productos tienen toggle de activación independiente.

## User Stories

1. Como buyer, quiero registrarme desde la app y acceder al catálogo de productos, para explorar y comprar artesanías.
2. Como buyer, quiero ver solo productos y artesanos activos, para no encontrar contenido deshabilitado.
3. Como gallery admin, quiero crear y gestionar artesanos (CRUD), para mantener actualizado mi catálogo.
4. Como gallery admin, quiero crear y gestionar productos (CRUD), para ofrecer nuevas artesanías.
5. Como gallery admin, quiero activar o desactivar un artesano con un toggle, para controlar su visibilidad sin borrarlo.
6. Como gallery admin, quiero activar o desactivar un producto con un toggle, para controlar su disponibilidad.
7. Como gallery admin, quiero desactivar un artesano con cascada opcional sobre sus productos, para aplicar cambios masivos cuando sea necesario.
8. Como gallery admin, quiero ver todos mis artesanos y productos (activos e inactivos), para gestionarlos incluso cuando están deshabilitados.
9. Como gallery admin, quiero que el sistema rechace borrar un artesano que tiene productos, para evitar pérdida accidental de datos.
10. Como gallery admin, quiero configurar la tasa de comisión de mi galería, para controlar mis ingresos por venta.
11. Como gallery admin, quiero ver un dashboard con métricas de mi galería (artesanos activos, productos, comisión), para monitorear mi negocio.
12. Como sistema, quiero que solo los gallery admins accedan a endpoints de administración, para proteger operaciones sensibles.
13. Como sistema, quiero que el rol y gallery_id viajen en el JWT, para autorizar sin queries extra por request.

## Implementation Decisions

### Modelo de roles

- Se agrega campo `Role string` al modelo `User` con valores `"buyer"` o `"gallery_admin"`.
- Un `gallery_admin` tiene exactamente una `Gallery` (ADR-0005). Un `buyer` no tiene ninguna.
- El rol se asigna en `POST /auth/register`. Los buyers se registran desde la app. Los admins se crean desde backend con `invite_code`.
- Login y register devuelven JWT con claims `sub` (userID), `role`, y `gallery_id` (si es admin).
- `POST /galleries` emite un nuevo token con `gallery_id` incluido.

### Estado de entidades

- `Artisan` y `Product` ganan campo `IsActive bool` (default `true` en migración).
- Endpoints públicos (`/api/explore/products`, `/api/products/:id`, `/api/artisans/:id`) filtran por `is_active = true`.
- Endpoints admin bajo `/galleries/:gid` devuelven todas las entidades sin filtrar.

### Toggle

- `POST /galleries/:gid/artisans/:id/toggle-active` — invierte `is_active`.
- `POST /galleries/:gid/products/:id/toggle-active` — invierte `is_active`.
- Query param `?cascade=true` en toggle de artesano desactiva/reactiva todos sus productos.

### Rutas

Rutas públicas (sin cambios de URL, agregan filtro `is_active`):
- `GET /api/explore/products`
- `GET /api/explore/products/:id`
- `GET /api/artisans/:id`

Rutas buyer (sin cambios):
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `POST /api/favorites/:product_id`
- `GET /api/favorites`
- `POST /api/checkout`
- `POST /api/checkout/save`
- `POST /api/checkout/complete`
- `GET /api/payments`

Rutas admin (nuevas o re-ubicadas bajo `AuthRequired` + `RequireGalleryOwner`):
- `POST /api/galleries` — crear galería (admin only, devuelve nuevo token)
- `GET /api/galleries` — listar galerías del user
- `GET /api/galleries/:gid` — detalle de galería (dashboard)
- `PUT /api/galleries/:gid/commission` — setear comisión
- `POST /api/galleries/:gid/artisans` — crear artesano (crea + asocia)
- `GET /api/galleries/:gid/artisans` — listar artesanos de la galería
- `PATCH /api/galleries/:gid/artisans/:id` — editar artesano
- `DELETE /api/galleries/:gid/artisans/:id` — borrar artesano (rechaza si tiene productos)
- `POST /api/galleries/:gid/artisans/:id/toggle-active` — toggle artesano
- `POST /api/galleries/:gid/artisans/:id/products` — crear producto
- `GET /api/galleries/:gid/artisans/:id/products` — productos de un artesano
- `GET /api/galleries/:gid/products` — todos los productos de la galería
- `PATCH /api/galleries/:gid/products/:id` — editar producto
- `DELETE /api/galleries/:gid/products/:id` — borrar producto
- `POST /api/galleries/:gid/products/:id/toggle-active` — toggle producto
- `POST /api/galleries/:gid/link-artisan/:artisan_id` — asociar artesano existente
- `DELETE /api/galleries/:gid/link-artisan/:artisan_id` — desasociar artesano

### Middleware

- `AuthRequired` (existente): valida JWT, inyecta `userID` en contexto.
- `RequireGalleryOwner` (nuevo): extrae `gallery_id` de la URL, lo compara con el `gallery_id` del JWT. Si no coinciden → 403.

### Flutter

- `Session` y `User` ganan campo `role`. `Session` gana `galleryId`.
- El `GoRouter` redirige a shell buyer o admin según `role`.
- **Buyer shell**: tabs Explorar, Historial (sin cambios).
- **Admin shell**: tabs Dashboard, Artesanos, Productos, Configuración.
- El registro desde la app solo crea buyers. Los admins se crean vía backend.
- La app admin usa `galleryId` del JWT para todas las llamadas a endpoints anidados.

## Testing Decisions

- Tests de integración sobre handlers, usando el patrón existente en `backend/internal/gallery/service/*_test.go`.
- Verificar comportamiento público (qué devuelve el endpoint), no implementación interna.
- Prioridad: middleware `RequireGalleryOwner` (403 a no-owners), toggle (invierte estado), filtro `is_active` en endpoints públicos.
- Prior art: `auth_test.go`, `artisan_test.go`, `product_test.go`.

## Out of Scope

- Múltiples galerías por usuario.
- Invitaciones o colaboradores por galería.
- Dashboard analytics en tiempo real (métricas básicas OK).
- Notificaciones para cambios de estado.
- Historial de cambios de estado (audit log).

## Further Notes

- Las rutas planas antiguas (`POST /api/artisans`, `POST /api/artisans/:id/products`, `DELETE /api/products/:id`) se eliminan — breaking change.
- `IsActive` default `true` en migración para que datos existentes sigan visibles.
- `RequireGalleryOwner` no requiere query a DB porque compara `gallery_id` del JWT con el de la URL.
