---
target: módulo admin (gallery)
total_score: 20
p0_count: 1
p1_count: 4
timestamp: 2026-07-03T02-12-14Z
slug: app-lib-screen-admin
---
# Critique: módulo admin (gallery) — app/lib/screen/admin

## Design Health Score

| # | Heurística | Score | Problema clave |
|---|-----------|-------|-----------|
| 1 | Visibilidad de estado | 2 | Skeletons y pull-to-refresh bien; pero toggles/deletes sin feedback de éxito, `catch (_) {}` silencia errores de mutación, upload sin progreso |
| 2 | Sistema ↔ mundo real | 3 | Español claro; "Wallet Address URL" como label de form es jerga |
| 3 | Control y libertad | 2 | Confirmación en deletes, sí; sin undo; sin cancelar upload |
| 4 | Consistencia | 1 | FAB `inverseSurface` vs botón primario terracota; títulos de página Playfair (dashboard/ajustes) vs Inter (artesanos/productos); `Colors.red` hardcodeado vs `cs.error`; dos patrones de estado (Riverpod provider vs setState manual) para la misma entidad |
| 5 | Prevención de errores | 2 | Validación solo al submit, error único al fondo del form, sin input formatters en precio/comisión |
| 6 | Reconocimiento | 2 | Tap en card de artesano no hace nada; crear producto desde tab Productos no existe (ruta oculta: Artesanos → artesano → Productos → FAB) |
| 7 | Flexibilidad/eficiencia | 1 | Sin búsqueda ni filtros en admin, sin acciones bulk, sin paginación |
| 8 | Estética/minimalismo | 3 | Restrained, cards limpias; métrica "Productos" duplicada en dashboard es ruido |
| 9 | Recuperación de errores | 2 | AppErrorState con retry en cargas (bien); mutaciones silenciadas; `Error: $e` y `e.toString()` crudos al usuario |
| 10 | Ayuda/documentación | 2 | Empty states enseñan ("Agrega tu primer artesano con el botón +"); sin onboarding |
| **Total** | | **20/40** | **Acceptable (borde bajo)** |

## Anti-Patterns Verdict

**LLM**: no parece AI-slop genérico — paleta tierra propia, cards contenidas, sin gradients ni glassmorphism. El tell es otro: inconsistencia interna (4 estilos de acción primaria distintos) y ~380 líneas de `_ProductCard`/`_StatusChip`/`_PhotoFallback`/`_Skeleton*` copiadas entre `products_screen.dart` y `artisan_products_screen.dart`, ya divergiendo.

**Detector**: 0 hallazgos — Dart no es escaneable por detect.mjs (targets HTML/CSS/JSX). Sin señal determinística.

**Browser**: sin dev server corriendo; app Flutter móvil → overlay no disponible.

## Priority Issues

- **[P0] Sin vista de pagos/liquidaciones para el operador.** PRODUCT.md: el operador "necesita claridad sobre el estado de los pagos split y las liquidaciones pendientes". No existe en el admin. Backend ya tiene `handler/payment.go` y el lado buyer ya tiene `payments_provider.dart`, `payment_card.dart`, `status_badge.dart`, `split_payment_bar.dart` — reutilizables. Fix: tab o sección "Pagos" en admin + dashboard con ingresos. Comando: /impeccable shape.
- **[P1] Jerarquía de acciones invertida en cards.** En card de producto la única acción visible es "Eliminar" (destructiva, permanente); editar está enterrado (tap → detalle → icono). FAB usa `inverseSurface` (café) en vez del terracota primario — la única acción que merece el acento no lo usa. Fix: FAB primario terracota; "Eliminar" fuera de la card (al detalle u overflow menu); editar accesible. Comando: /impeccable polish.
- **[P1] Texto "Galería N%" ilegible.** `products_screen.dart:342` y `artisan_products_screen.dart:357` pintan el label con `cs.secondary` (#E8DED7) sobre card #F8F4F1 → contraste ~1.1:1, invisible. La barra del split de galería igual. Fix: usar `onSecondaryContainer`/`arena` para el texto, tono más oscuro para la barra; reutilizar `split_payment_bar.dart`. Comando: /impeccable polish.
- **[P1] Fallos silenciosos y feedback ausente.** `artisan_products_screen.dart:65,102`: `catch (_) {}` — toggle/delete fallan sin avisar, el switch queda mintiendo. Ninguna mutación confirma éxito (snackbar). Errores crudos `Error: $e` al usuario. Fix: snackbars éxito/error en español, sin excepciones crudas. Comando: /impeccable harden.
- **[P1] Dashboard roto y no accionable.** `dashboard_screen.dart:66-88`: métrica "Productos" duplicada (Row + card full-width idéntica). Métricas no navegan a su tab. Dashboard = nombre + 2 números. Fix: quitar duplicado, tiles tappables, agregar pagos recientes/ingresos cuando exista P0. Comando: /impeccable polish.

## Persona Red Flags

**Alex (operador power user)**: crear producto = 4 saltos (tab Artesanos → artesano → Productos → FAB); tab Productos ni siquiera tiene FAB, el empty state dice "Crea productos desde la vista de cada artesano" sin botón. Sin búsqueda con 30+ productos, scroll manual. Sin bulk activate/deactivate.

**Sam (accesibilidad)**: IconButtons de 16px con `visualDensity.compact` + `Size.zero` → targets ~32px, viola la regla ≥48px de PRODUCT.md ("targets táctiles generosos para manos que trabajan"). Switch sin Semantics label (screen reader: "switch on" — ¿de cuál producto?). StatusChip fontSize 10. Estado activo/inactivo comunicado por color+desaturación de foto sin texto equivalente en card de producto (el chip sí lo tiene — bien).

**Operador de galería (persona del proyecto — PRODUCT.md)**: no puede responder "¿cuánto vendí este mes?", "¿qué liquidaciones están pendientes?" — la razón de ser del rol. Wallet del artesano se valida solo al submit; un typo en la URL = pagos que no llegan al artesano, sin verificación visible.

## Minor Observations

- Card de artesano: nombre (identidad primaria) abajo del divider, acciones arriba — jerarquía invertida; tap en card no hace nada; 3 affordances distintas en una fila (TextButton + 2 IconButtons); doble señal Activo/Inactivo (switch label + badge).
- Títulos de página: Playfair Display serif en dashboard/ajustes vs Inter bold en listas — DESIGN.md dice "single sans family, no serif pairing"; el theme se contradice a sí mismo.
- Forms: error único abajo del scroll mientras el campo ofensor está arriba; sin `TextFormField`/validación inline; comisión sin preview del split (backlog lo pide; `split_payment_bar.dart` ya existe).
- `product_form_screen.dart:49,138`: precio hardcodea `/100` y `'USD'` — asume assetScale 2.
- Estado stale: toggle en vista artesano-productos no invalida `adminProductsProvider` → tab Productos desincronizado.
- `Colors.red` en settings logout y detail delete en vez de `cs.error`.
- `_CountPill` sin significado explícito ("3 / 5" — ¿activos/total? sin label).

## Questions to Consider

- ¿Qué pasa si el dashboard fuera la bandeja de trabajo del operador (pagos pendientes, productos sin foto, artesanos sin wallet) en vez de 2 contadores?
- ¿La card de producto necesita switch + eliminar visibles, o basta tap → detalle con todas las acciones?
- ¿Un solo componente `AdminProductCard` compartido eliminaría la divergencia de una vez?
