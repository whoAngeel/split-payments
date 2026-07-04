# Bugs

## ~~Checkout: "gallery no tiene comisión seteada"~~ :heavy_check_mark: arreglado

- **Archivo:** `backend/internal/gallery/service/checkout.go`
- **Causa:** El checkout usaba `gallery.Commission.Rate` (tabla `commissions`, seteada por API separada) en vez de `product.CommissionRate` (seteado al crear el producto).
- **Fix:** Ahora usa `product.CommissionRate` como fuente primaria, con fallback a `gallery.Commission.Rate` si es 0.

## ~~Checkout: no se ve la imagen del producto~~ :heavy_check_mark: arreglado

- **Archivo:** `app/lib/screen/checkout/checkout_screen.dart`
- **Causa:** La imagen usaba `product.imageUrl` (ruta relativa) sin anteponer `baseUrl`. Otros widgets como `product_card.dart` sí lo hacen.
- **Fix:** Agregada la misma lógica de `product_card.dart`: si la URL no empieza con `http`, se antepone `baseUrl`.

## ~~Dashboard: comisión muestra 0~~ :heavy_check_mark: arreglado

- **Archivo:** `backend/internal/gallery/service/payment.go`
- **Causa:** `Save()` usaba `gallery.Commission.Rate` (nunca seteado) en vez de `product.CommissionRate`.
- **Fix:** Ahora usa `product.CommissionRate` como fuente primaria, con fallback a `gallery.Commission.Rate`.

## ~~Cámara: foto en portrait se guarda como landscape~~ :heavy_check_mark: arreglado

- **Archivos:** `app/lib/utils/image_utils.dart` (nuevo), `app/lib/screen/admin/products/product_form_screen.dart`, `app/lib/screen/admin/products/product_detail_screen.dart`
- **Causa:** `image_picker` comprime la imagen sin aplicar la orientación EXIF. La imagen se subía con los píxeles en orientación nativa del sensor (landscape).
- **Fix:** Se agregó `fixExifOrientation()` usando el paquete `image` que "hornea" la rotación EXIF en los píxeles antes de subirla.

## ~~Explore: chips de filtro~~ :heavy_check_mark: removidos

- **Archivo probable:** `app/lib/screen/explore/explore_screen.dart`
- **Descripción:** Los chips de filtrado en la vista de exploración son innecesarios o confusos para el MVP actual.
- **Acción:** Remover los chips de filtro de la UI.

## ~~Tipografía inconsistente en títulos~~ :heavy_check_mark: arreglado

- **Archivos:** `app/lib/screen/admin/artisans/artisans_screen.dart`, `app/lib/screen/admin/products/products_screen.dart`
- **Causa:** Artesanos y Productos usaban `titleLarge`, Dashboard y Pagos usaban `headlineSmall`.
- **Fix:** Unificado a `headlineSmall` + `w700` en todas las vistas admin.
