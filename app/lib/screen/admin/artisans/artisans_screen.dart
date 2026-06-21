import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/models/artisan.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/widgets/app_empty_state.dart';
import 'package:openpayments_app/widgets/app_error_state.dart';

class AdminArtisansScreen extends ConsumerStatefulWidget {
  const AdminArtisansScreen({super.key});

  @override
  ConsumerState<AdminArtisansScreen> createState() => _AdminArtisansScreenState();
}

class _AdminArtisansScreenState extends ConsumerState<AdminArtisansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(artisansProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final artisansAsync = ref.watch(artisansProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/artisans/new'),
        backgroundColor: cs.inverseSurface,
        foregroundColor: cs.onInverseSurface,
        child: const Icon(Icons.add),
      ),
      body: artisansAsync.when(
        loading: () => const _SkeletonList(),
        error: (e, _) => AppErrorState(
          message: 'Error al cargar artesanos',
          onRetry: () => ref.invalidate(artisansProvider),
        ),
        data: (artisans) {
          if (artisans.isEmpty) {
            return AppEmptyState(
              icon: Icons.people_outlined,
              title: 'Sin artesanos',
              description: 'Agrega tu primer artesano con el botón +',
            );
          }

          final active = artisans.where((a) => a.isActive).length;

          return RefreshIndicator(
            onRefresh: () => ref.read(artisansProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        Text(
                          'Artesanos',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$active / ${artisans.length}',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: artisans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) =>
                        _ArtisanCard(artisan: artisans[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Artisan Card ─────────────────────────────────────────────────────────────

class _ArtisanCard extends ConsumerWidget {
  final Artisan artisan;
  const _ArtisanCard({required this.artisan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isActive = artisan.isActive;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: isActive ? null : Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: [foto | acciones]
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Foto — fixed width, fills height of right col
                SizedBox(
                  width: 130,
                  child: _ArtisanBanner(artisan: artisan),
                ),
                VerticalDivider(width: 1, color: cs.outlineVariant),
                // Acciones — drives card height
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle
                        Row(
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (_) => _toggleArtisan(context, ref),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? 'Activo' : 'Inactivo',
                              style: tt.labelSmall?.copyWith(
                                color: isActive ? cs.primary : cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Ver productos · editar · eliminar (una fila)
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () => context.push(
                                  '/admin/artisans/${artisan.id}/products',
                                  extra: artisan.name,
                                ),
                                icon: const Icon(Icons.inventory_2_outlined, size: 13),
                                label: const Text('Productos'),
                                style: TextButton.styleFrom(
                                  foregroundColor: cs.onSurfaceVariant,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                  textStyle: tt.labelSmall?.copyWith(fontWeight: FontWeight.w500),
                                  alignment: Alignment.centerLeft,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.push('/admin/artisans/${artisan.id}/edit'),
                              icon: Icon(Icons.edit_outlined, size: 16, color: cs.onSurfaceVariant),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Editar artesano',
                            ),
                            IconButton(
                              onPressed: () => _confirmDelete(context, ref),
                              icon: Icon(Icons.delete_outline, size: 16, color: cs.error),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Eliminar artesano',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: cs.outlineVariant),

          // Row 2: nombre + wallet (full width)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        artisan.name,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isActive ? cs.onSurface : cs.onSurfaceVariant,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isActive) ...[
                      const SizedBox(width: 8),
                      _InactiveBadge(cs: cs, tt: tt),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 13,
                      color: artisan.walletAddressUrl.isNotEmpty
                          ? cs.primary
                          : cs.outlineVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        artisan.walletAddressUrl.isNotEmpty
                            ? artisan.walletAddressUrl
                            : 'Sin wallet',
                        style: tt.bodySmall?.copyWith(
                          color: artisan.walletAddressUrl.isNotEmpty
                              ? cs.onSurfaceVariant
                              : cs.outlineVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleArtisan(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final willActivate = !artisan.isActive;
    final verb = willActivate ? 'activar' : 'desactivar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${willActivate ? 'Activar' : 'Desactivar'} artesano'),
        content: Text(
          '¿También quieres $verb los productos de ${artisan.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(artisansProvider.notifier).toggleActive(artisan.id);
            },
            child: const Text('Solo el artesano'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(artisansProvider.notifier).toggleActive(artisan.id, cascade: true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.inverseSurface,
              foregroundColor: cs.onInverseSurface,
            ),
            child: const Text('Artesano y productos'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar artesano'),
        content: Text('¿Eliminar a ${artisan.name}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(artisansProvider.notifier).delete(artisan.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ─── Artisan Photo ────────────────────────────────────────────────────────────

class _ArtisanBanner extends ConsumerWidget {
  final Artisan artisan;
  const _ArtisanBanner({required this.artisan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final initials = _initials(artisan.name);
    final baseUrl = ref.read(apiClientProvider).baseUrl;
    final imageUrl = artisan.imageUrl.isNotEmpty ? '$baseUrl${artisan.imageUrl}' : '';

    Widget content = imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _initialsBlock(initials, cs, tt),
          )
        : _initialsBlock(initials, cs, tt);

    if (!artisan.isActive) {
      content = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: Opacity(opacity: 0.55, child: content),
      );
    }

    return SizedBox.expand(child: content);
  }

  Widget _initialsBlock(String initials, ColorScheme cs, TextTheme tt) {
    return Container(
      color: cs.primaryContainer,
      child: Center(
        child: Text(
          initials,
          style: tt.displayMedium?.copyWith(
            color: cs.onPrimaryContainer.withValues(alpha: 0.35),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─── Inactive Badge ───────────────────────────────────────────────────────────

class _InactiveBadge extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;

  const _InactiveBadge({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        'Inactivo',
        style: tt.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      itemCount: 5,
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
        children: [
          // Row 1 skeleton: [foto | acciones]
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 130, color: block),
                Container(width: 1, color: cs.outlineVariant),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Rect(w: 44, h: 20, r: 10, color: block),
                        const Spacer(),
                        Row(
                          children: [
                            _Rect(w: 72, h: 10, color: block),
                            const Spacer(),
                            _Rect(w: 18, h: 18, r: 4, color: block),
                            const SizedBox(width: 6),
                            _Rect(w: 18, h: 18, r: 4, color: block),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          // Row 2 skeleton: nombre + wallet
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Rect(w: 140, h: 13, color: block),
                const SizedBox(height: 6),
                _Rect(w: 190, h: 9, color: block),
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

  const _Rect({required this.w, required this.h, required this.color, this.r = 4});

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
