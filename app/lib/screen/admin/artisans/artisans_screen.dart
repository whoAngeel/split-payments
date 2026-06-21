import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/models/artisan.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
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
        color: isActive ? cs.surfaceContainerLow : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? null
            : Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ArtisanPhoto(artisan: artisan, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              artisan.name,
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
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
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 11,
                            color: artisan.walletAddressUrl.isNotEmpty
                                ? cs.primary
                                : cs.outlineVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              artisan.walletAddressUrl.isNotEmpty
                                  ? artisan.walletAddressUrl
                                  : 'Sin wallet',
                              style: tt.labelSmall?.copyWith(
                                color: artisan.walletAddressUrl.isNotEmpty
                                    ? cs.onSurfaceVariant
                                    : cs.outlineVariant,
                                letterSpacing: 0,
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
          ),

          Divider(height: 1, color: cs.outlineVariant),

          // Action row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
            child: Row(
              children: [
                Switch(
                  value: isActive,
                  onChanged: (_) => _toggleArtisan(context, ref),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? 'Activo' : 'Inactivo',
                  style: tt.labelSmall?.copyWith(
                    color: isActive ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push(
                    '/admin/artisans/${artisan.id}/products',
                    extra: artisan.name,
                  ),
                  icon: const Icon(Icons.inventory_2_outlined, size: 14),
                  label: const Text('Productos'),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    textStyle: tt.labelSmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                PopupMenuButton<String>(
                  iconSize: 20,
                  icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
                  onSelected: (action) => _onAction(action, context, ref),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(value: 'products', child: Text('Ver productos')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Eliminar',
                        style: TextStyle(color: cs.error),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar estado'),
        content: const Text('¿Aplicar el cambio a todos los productos de este artesano también?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(artisansProvider.notifier).toggleActive(artisan.id);
            },
            child: const Text('Solo artesano'),
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
            child: const Text('Con productos'),
          ),
        ],
      ),
    );
  }

  void _onAction(String action, BuildContext context, WidgetRef ref) {
    switch (action) {
      case 'edit':
        context.push('/admin/artisans/${artisan.id}/edit');
      case 'products':
        context.push('/admin/artisans/${artisan.id}/products', extra: artisan.name);
      case 'delete':
        _confirmDelete(context, ref);
    }
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

class _ArtisanPhoto extends StatelessWidget {
  final Artisan artisan;
  final double size;

  const _ArtisanPhoto({required this.artisan, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final initials = _initials(artisan.name);
    final isActive = artisan.isActive;

    Widget photo = artisan.imageUrl.isNotEmpty
        ? ClipOval(
            child: Image.network(
              artisan.imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialsWidget(initials, cs, tt),
            ),
          )
        : _initialsWidget(initials, cs, tt);

    if (!isActive) {
      photo = Opacity(opacity: 0.45, child: photo);
    }

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primaryContainer,
            border: Border.all(
              color: isActive
                  ? cs.primary.withValues(alpha: 0.25)
                  : cs.outlineVariant,
              width: 2,
            ),
          ),
          child: ClipOval(child: photo),
        ),
        if (isActive)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initialsWidget(String initials, ColorScheme cs, TextTheme tt) {
    return Container(
      width: size,
      height: size,
      color: cs.primaryContainer,
      child: Center(
        child: Text(
          initials,
          style: tt.titleSmall?.copyWith(
            color: cs.onPrimaryContainer,
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: block, shape: BoxShape.circle),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      _Rect(w: 140, h: 13, color: block),
                      const SizedBox(height: 8),
                      _Rect(w: 160, h: 9, color: block),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _Rect(w: 44, h: 20, r: 10, color: block),
                const SizedBox(width: 8),
                _Rect(w: 40, h: 9, color: block),
                const Spacer(),
                _Rect(w: 72, h: 24, r: 6, color: block),
                const SizedBox(width: 8),
                _Rect(w: 20, h: 20, r: 4, color: block),
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
