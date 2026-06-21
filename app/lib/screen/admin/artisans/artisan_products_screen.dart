import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/models/admin_product.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/widgets/app_empty_state.dart';
import 'package:openpayments_app/widgets/app_error_state.dart';

class AdminArtisanProductsScreen extends ConsumerStatefulWidget {
  final int artisanId;
  final String artisanName;
  const AdminArtisanProductsScreen(
      {super.key, required this.artisanId, required this.artisanName});

  @override
  ConsumerState<AdminArtisanProductsScreen> createState() =>
      _AdminArtisanProductsScreenState();
}

class _AdminArtisanProductsScreenState
    extends ConsumerState<AdminArtisanProductsScreen> {
  List<AdminProduct> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await ref
          .read(galleryServiceProvider)
          .getArtisanProducts(session.galleryId, widget.artisanId);
      if (mounted) setState(() => _products = products);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'No se pudieron cargar los productos. Verifica tu conexión e intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(AdminProduct p) async {
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) return;
    try {
      await ref
          .read(galleryServiceProvider)
          .toggleProductActive(session.galleryId, p.id);
      _load();
    } catch (_) {}
  }

  Future<void> _confirmDelete(AdminProduct p) async {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${p.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: Text('Eliminar', style: tt.labelLarge),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) return;
    try {
      await ref
          .read(galleryServiceProvider)
          .deleteProduct(session.galleryId, p.id);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseUrl = ref.read(apiClientProvider).baseUrl;

    Widget body;

    if (_loading) {
      body = _SkeletonList();
    } else if (_error != null) {
      body = AppErrorState(
        message: _error!,
        onRetry: _load,
      );
    } else if (_products.isEmpty) {
      body = AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Sin productos',
        description: 'Crea el primer producto de ${widget.artisanName}.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList.separated(
                itemCount: _products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) => _ProductCard(
                  product: _products[i],
                  baseUrl: baseUrl,
                  onToggle: () => _toggle(_products[i]),
                  onDelete: () => _confirmDelete(_products[i]),
                  onTap: () => context.push('/admin/products/${_products[i].id}'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artisanName),
        scrolledUnderElevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context
              .push('/admin/artisans/${widget.artisanId}/products/new');
          _load();
        },
        backgroundColor: cs.inverseSurface,
        foregroundColor: cs.onInverseSurface,
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}

// ─── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final AdminProduct product;
  final String baseUrl;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _ProductCard({
    required this.product,
    required this.baseUrl,
    required this.onToggle,
    required this.onDelete,
    this.onTap,
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
        ? Image.network(
            _photoUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _PhotoFallback(cs: cs, tt: tt),
          )
        : _PhotoFallback(cs: cs, tt: tt);

    if (!isActive) {
      photo = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: Opacity(opacity: 0.6, child: photo),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: isActive ? null : Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          Stack(
            children: [
              SizedBox(
                height: 176,
                width: double.infinity,
                child: photo,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _StatusChip(isActive: isActive, cs: cs, tt: tt),
              ),
            ],
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + toggle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:
                              isActive ? cs.onSurface : cs.onSurfaceVariant,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isActive,
                      onChanged: (_) => onToggle(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Artisan name
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      product.artisanName,
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),

                Divider(height: 20, color: cs.outlineVariant),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Precio',
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
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
                  // Split bar
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
                          child: Container(height: 5, color: cs.secondary),
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
                          color: cs.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                Divider(height: 16, color: cs.outlineVariant),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline,
                          size: 14, color: cs.error),
                      label: Text(
                        'Eliminar',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.error, fontWeight: FontWeight.w500),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─── Status Chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isActive;
  final ColorScheme cs;
  final TextTheme tt;

  const _StatusChip(
      {required this.isActive, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? cs.primaryContainer.withValues(alpha: 0.92)
            : cs.surfaceContainerHighest.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? cs.primary.withValues(alpha: 0.2) : cs.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? cs.primary : cs.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Activo' : 'Inactivo',
            style: tt.labelSmall?.copyWith(
              color:
                  isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Photo Fallback ────────────────────────────────────────────────────────────

class _PhotoFallback extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;

  const _PhotoFallback({required this.cs, required this.tt});

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

// ─── Skeleton ──────────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
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
                Row(children: [
                  _Rect(w: 40, h: 10, color: block),
                  const Spacer(),
                  _Rect(w: 80, h: 14, color: block),
                ]),
                const SizedBox(height: 10),
                _Rect(w: double.infinity, h: 5, r: 3, color: block),
                const SizedBox(height: 6),
                Row(children: [
                  _Rect(w: 70, h: 9, color: block),
                  const Spacer(),
                  _Rect(w: 60, h: 9, color: block),
                ]),
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

  const _Rect(
      {required this.w, required this.h, required this.color, this.r = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(r)),
    );
  }
}
