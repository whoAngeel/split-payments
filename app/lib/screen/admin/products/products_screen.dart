import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/models/admin_product.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/widgets/app_empty_state.dart';
import 'package:openpayments_app/widgets/app_error_state.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProductsProvider.notifier).refresh();
    });
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
    ref.read(adminProductsProvider.notifier).delete(p.id);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final baseUrl = ref.read(apiClientProvider).baseUrl;

    return productsAsync.when(
      loading: () => _SkeletonList(),
      error: (_, __) => AppErrorState(
        message: 'No se pudieron cargar los productos.',
        onRetry: () => ref.invalidate(adminProductsProvider),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Sin productos',
            description: 'Crea productos desde la vista de cada artesano.',
          );
        }

        final active = products.where((p) => p.isActive).length;

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(adminProductsProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'Productos',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                      ),
                      const SizedBox(width: 10),
                      _CountPill(
                          active: active,
                          total: products.length),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 16),
                  itemBuilder: (_, i) => _ProductCard(
                    product: products[i],
                    baseUrl: baseUrl,
                    onToggle: () => ref
                        .read(adminProductsProvider.notifier)
                        .toggleActive(products[i].id),
                    onDelete: () => _confirmDelete(products[i]),
                    onTap: () => context.push('/admin/products/${products[i].id}'),
                  ),
                ),
              ),
        ],
      ),
    );
      },
    );
  }
}

// ─── Count Pill ────────────────────────────────────────────────────────────────

class _CountPill extends StatelessWidget {
  final int active;
  final int total;
  const _CountPill({required this.active, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$active / $total',
        style: tt.labelSmall?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
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
            errorBuilder: (_, __, ___) => _PhotoFallback(cs: cs),
          )
        : _PhotoFallback(cs: cs);

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
          Stack(
            children: [
              SizedBox(height: 176, width: double.infinity, child: photo),
              Positioned(
                top: 10,
                right: 10,
                child: _StatusChip(isActive: isActive, cs: cs, tt: tt),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
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
                    Switch(
                      value: isActive,
                      onChanged: (_) => onToggle(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline,
                          size: 14, color: cs.error),
                      label: Text(
                        'Eliminar',
                        style: tt.labelSmall?.copyWith(
                          color: cs.error,
                          fontWeight: FontWeight.w500,
                        ),
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
          color: isActive
              ? cs.primary.withValues(alpha: 0.2)
              : cs.outlineVariant,
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
              color: isActive
                  ? cs.onPrimaryContainer
                  : cs.onSurfaceVariant,
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}
