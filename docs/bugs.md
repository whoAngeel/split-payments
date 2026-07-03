# Bugs

## Checkout: "gallery no tiene comisión seteada"

- **Archivo probable:** `backend/internal/gallery/service/checkout.go` (validación de comisión)
- **Descripción:** Al intentar pagar, el backend rechaza la operación diciendo que la galería no tiene comisión configurada, a pesar de que el producto sí la tiene asociada.
- **Posible causa:** La validación busca la comisión a nivel de galería (`gallery_id`) y no a nivel de producto. Si la galería no tiene un registro en la tabla `commissions`, aunque el producto tenga `commission_rate`, falla.

## Checkout: no se ve la imagen del producto

- **Archivo probable:** `app/lib/screen/checkout/checkout_screen.dart` (widget de imagen)
- **Descripción:** En la pantalla de checkout, la imagen del producto no se renderiza.
- **Posible causa:** La URL de la imagen usa `http` en vez de `https`, o la ruta no se construye correctamente con el `baseUrl` actual (Cloudflare tunnel).

## Cámara: foto en portrait se guarda como landscape

- **Archivo probable:** `app/lib/screen/admin/products/product_form_screen.dart` (captura de imagen)
- **Descripción:** Al tomar una foto con el teléfono en posición vertical, la imagen se guarda rotada 90°, como si estuviera en horizontal. Solo salen bien si se toma la foto con el teléfono acostado.
- **Posible causa:** No se está leyendo/rotando la imagen según los metadatos EXIF (`Orientation`). Al guardar la imagen redimensionada se pierde la orientación original. Falta usar `readAsBytes` + `img.decodeImage` + `bakeOrientation` del paquete `image`.

## ~~Explore: chips de filtro~~ :heavy_check_mark: removidos

- **Archivo probable:** `app/lib/screen/explore/explore_screen.dart`
- **Descripción:** Los chips de filtrado en la vista de exploración son innecesarios o confusos para el MVP actual.
- **Acción:** Remover los chips de filtro de la UI.

## Tipografía inconsistente en títulos

- **Archivos probables:** `app/lib/screen/admin/artisans/*`, `app/lib/screen/admin/products/*`
- **Descripción:** Las vistas de Artesanos y Productos usan una tipografía diferente para los títulos que la usada en el Dashboard. Deberían ser consistentes.
- **Acción:** Unificar el estilo de tipografía para los títulos en todas las vistas de admin.
