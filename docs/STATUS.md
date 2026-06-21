# Estado del Proyecto — Junio 2026

## Lo que ya funciona

### Backend (Gallery API + Splitter)

**Auth y Roles**
- Registro de buyers desde la app (`POST /api/auth/register`, role=buyer)
- Registro de admins con `invite_code` (crea User + Gallery en un paso)
- Login con JWT: claims `sub`, `role`, `gallery_id`
- Middleware `AuthRequired` + `RequireGalleryOwner` encadenados
- Una galería por usuario (ADR-0005)

**Artisan CRUD**
- Create, Read, Update, Delete bajo `GET|POST|PATCH|DELETE /galleries/:gid/artisans`
- Campos: name, wallet, image_url, bio, location, specialty, craft_type, tags
- Toggle activo/inactivo con cascada opcional (`?cascade=true`)
- Delete rechazado si tiene productos (409)
- Foto de perfil con upload a MinIO (thumb 200px + medium 800px)

**Product CRUD**
- Create, Read, Update, Delete bajo `/galleries/:gid/artisans/:id/products` y `/galleries/:gid/products`
- Campos: name, base_price, asset_code, asset_scale, image_url, commission_rate
- Campos de detalle: description, materials, dimensions, tags (tabla `product_details`)
- Toggle activo/inactivo
- Comisión por producto (no por galería)
- Imágenes de producto: add/list/delete (`GET|POST|DELETE /galleries/:gid/products/:id/images`)

**Upload de imágenes**
- `POST /api/upload` — recibe imagen, genera thumb (200x200, JPEG 72%) y medium (800px, JPEG 85%)
- Almacenamiento en MinIO (S3-compatible)
- Image proxy: `GET /products/*filepath` sirve desde MinIO
- Formatos aceptados: jpg, jpeg, png, webp, heic
- Límite: 5 imágenes por producto

**Dashboard**
- `GET /galleries/:gid` devuelve gallery info + conteos (artesanos activos/total, productos activos/total)
- `PUT /galleries/:gid/commission` mantiene compatibilidad

**Explore (buyer)**
- `GET /api/explore/products` — filtra por `is_active=true` (producto y artesano)
- `GET /api/explore/products/:id` — detalle con split, imágenes, tags, artesano
- `GET /api/artisans/:id` — público, filtra por activo

### Flutter App

**Auth y navegación**
- Dual-shell: buyer (Explorar, Historial) vs admin (Dashboard, Artesanos, Productos, Ajustes)
- Login/register con redirect automático según rol
- `sessionNotifier` + `refreshListenable` para evitar recrear GoRouter
- Logout desde Ajustes

**Admin — Dashboard**
- Métricas: artesanos activos/total, productos activos/total
- Nombre de la galería
- Pull-to-refresh

**Admin — Artesanos**
- Lista con foto (thumb), nombre, ubicación/especialidad, wallet
- Toggle activo/inactivo con diálogo de cascada
- Crear/editar artesano: form con nombre, wallet, ubicación, especialidad, craft type, bio, tags, foto (cámara o galería)
- Eliminar con confirmación
- Vista de productos por artesano (con crear producto desde ahí)

**Admin — Productos**
- Lista plana con toggle, delete
- Tap → detalle de producto
- Detalle: precio, comisión, descripción, materiales, dimensiones, tags, galería de imágenes
- Agregar/quitar imágenes (límite 5)
- Editar producto: form con todos los campos + imagen
- Eliminar con confirmación

**Admin — Ajustes**
- Cerrar sesión

**Buyer — Explore**
- Grid de productos con foto, nombre, precio, artesano, split
- Búsqueda por texto
- Detalle de producto: galería de imágenes, descripción, specs, artesano

**Buyer — Órdenes**
- Historial de pagos (si el splitter está corriendo)

**Validaciones**
- Artisan form: nombre requerido (min 2), wallet debe empezar con `https://`
- Product form: nombre requerido, precio > 0, comisión 0-100
- Product images: máximo 5

### Estructura del código

```
screen/
├── admin/
│   ├── dashboard/    dashboard_screen.dart
│   ├── artisans/     artisans_screen.dart, artisan_form_screen.dart, artisan_products_screen.dart
│   ├── products/     products_screen.dart, product_form_screen.dart, product_detail_screen.dart
│   └── settings/     settings_screen.dart
├── auth/             login_screen.dart, register_screen.dart
├── explore/          explore_screen.dart, product_detail_screen.dart
├── orders/           orders_screen.dart
├── checkout/         checkout_screen.dart
├── account/          account_screen.dart
├── payment/          payment_confirmation_screen.dart
└── home_screen.dart
```

---

## Lo que podríamos agregar

### Prioridad alta
- [ ] **Editar producto desde la lista** (actualmente solo desde detalle)
- [ ] **Preview de imágenes antes de subir** (artisan y product)
- [ ] **Eliminar foto de artesano** (actualmente solo se puede cambiar, no quitar)
- [ ] **Filtros en Explore**: por galería, por ubicación, por especialidad
- [ ] **Paginación** en listas de artesanos y productos
- [ ] **Ordenar productos** (arrastrar para reordenar)
- [ ] **Indicador de carga** al subir imágenes (ya tiene spinner, pero mejorar feedback)

### Prioridad media
- [ ] **WebSocket para notificaciones en tiempo real** (dashboard, cambios de estado)
- [ ] **Múltiples tamaños de imagen en el detalle** (usar thumb en listas, medium en detalle — ya funciona, falta en algunos lugares)
- [ ] **Eliminación masiva** de productos/artesanos
- [ ] **Exportar datos** (CSV de artesanos, productos, ventas)
- [ ] **Estadísticas del dashboard**: pagos completados, ingresos estimados
- [ ] **Buscar artesanos** en el admin
- [ ] **Dark mode**
- [ ] **Internacionalización** (español/inglés)

### Prioridad baja / ideas
- [ ] **Onboarding** para nuevos admins (tour guiado)
- [ ] **Vista previa del split** al crear producto (cuánto recibe artesano vs galería)
- [ ] **Categorías de productos** (más allá de tags)
- [ ] **Productos destacados** (pin al inicio del Explore)
- [ ] **Mensajes** entre gallery admin y artesanos
- [ ] **Audit log** de cambios (quién modificó qué y cuándo)
- [ ] **Tests E2E** con Flutter integration tests
- [ ] **CI/CD** (GitHub Actions para build + test)

### Deuda técnica
- [ ] El splitter tiene `SPLITTER_PUBLIC_URL` configurable pero el callback de pago falla en emulador (funciona en dispositivo físico)
- [ ] `api_client.dart` tiene un getter/setter innecesario para `token`
- [ ] Algunos endpoints no validan que el artesano pertenezca a la galería antes de crear producto
- [ ] Tests solo cubren la capa de servicio, no los handlers HTTP
- [ ] `ProductDetail.tags` cambió de `text[]` a `text` — migración manual necesaria en DB existentes
