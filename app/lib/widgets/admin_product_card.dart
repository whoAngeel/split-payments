import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openpayments_app/models/admin_product.dart';
import 'package:openpayments_app/widgets/app_image.dart';

/// Card de producto para las vistas de administración (lista global y por
/// artesano). Toda la card navega al detalle; el switch activa/desactiva.
/// Las acciones destructivas viven en la pantalla de detalle.
class AdminProductCard extends StatelessWidget {
  final AdminProduct product;
  final String baseUrl;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final bool showArtisan;

  const AdminProductCard({
    super.key,
    required this.product,
    required this.baseUrl,
    required this.onToggle,
    this.onTap,
    this.showArtisan = true,
  });

  String? get _photoUrl {
    if (product.imageUrl.isEmpty) return null;
    return product.imageUrl.startsWith('http')
        ? product.imageUrl
        : '$baseUrl${product.imageUrl}';
  }

  String _formatPrice() {
    final amount = product.basePrice / pow(10, product.assetScale);
    return '${product.assetCode} ${amount.toStringAsFixed(product.assetScale)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isActive = product.isActive;
    final galleryPct = product.commissionPercent.round().clamp(0, 100);
    final artisanPct = (100 - galleryPct).clamp(0, 100);
    final hasSplit = galleryPct > 0 && artisanPct > 0;

    Widget photo = _photoUrl != null
        ? AppImage(
            imageVariant(_photoUrl!, 'small'),
            fallbackUrl: _photoUrl,
            cacheWidth: 800,
          )
        : _PhotoFallback(cs: cs);

    if (!isActive) {
      photo = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Opacity(opacity: 0.6, child: photo),
      );
    }

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isActive ? null : Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(height: 176, width: double.infinity, child: photo),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _StatusChip(isActive: isActive),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? cs.onSurface
                                  : cs.onSurfaceVariant,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: product.isActive
                              ? 'Desactivar ${product.name}'
                              : 'Activar ${product.name}',
                          child: Switch(
                            value: isActive,
                            onChanged: (_) => onToggle(),
                          ),
                        ),
                      ],
                    ),
                    if (showArtisan) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.artisanName,
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    Divider(height: 20, color: cs.outlineVariant),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Precio',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatPrice(),
                          style: tt.titleMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),

                    if (hasSplit) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Row(
                          children: [
                            Expanded(
                              flex: artisanPct,
                              child: Container(height: 5, color: cs.primary),
                            ),
                            Expanded(
                              flex: galleryPct,
                              child: Container(
                                height: 5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            'Artesano $artisanPct%',
                            style: tt.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Galería $galleryPct%',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? cs.primaryContainer.withValues(alpha: 0.92)
            : cs.surfaceContainerHighest.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? cs.primary.withValues(alpha: 0.2)
              : cs.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? cs.primary : cs.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Activo' : 'Inactivo',
            style: tt.labelSmall?.copyWith(
              color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  final ColorScheme cs;
  const _PhotoFallback({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

/// Skeleton de carga para listas de [AdminProductCard].
class AdminProductSkeletonList extends StatelessWidget {
  const AdminProductSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final block = cs.surfaceContainerHighest;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 176, color: block),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Rect(w: 200, h: 14, color: block),
                const SizedBox(height: 8),
                _Rect(w: 120, h: 10, color: block),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Rect(w: 40, h: 10, color: block),
                    const Spacer(),
                    _Rect(w: 80, h: 14, color: block),
                  ],
                ),
                const SizedBox(height: 10),
                _Rect(w: double.infinity, h: 5, r: 3, color: block),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Rect(w: 70, h: 9, color: block),
                    const Spacer(),
                    _Rect(w: 60, h: 9, color: block),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Rect extends StatelessWidget {
  final double w;
  final double h;
  final double r;
  final Color color;

  const _Rect({
    required this.w,
    required this.h,
    required this.color,
    this.r = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}
