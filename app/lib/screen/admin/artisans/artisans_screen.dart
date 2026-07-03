import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/models/artisan.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/widgets/app_empty_state.dart';
import 'package:openpayments_app/widgets/app_error_state.dart';
import 'package:openpayments_app/widgets/app_image.dart';

class AdminArtisansScreen extends ConsumerStatefulWidget {
  const AdminArtisansScreen({super.key});

  @override
  ConsumerState<AdminArtisansScreen> createState() =>
      _AdminArtisansScreenState();
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
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        tooltip: 'Nuevo artesano',
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
              description:
                  'Registra a los artesanos de tu galería para poder publicar sus productos.',
              actionLabel: 'Agregar artesano',
              onAction: () => context.push('/admin/artisans/new'),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$active de ${artisans.length} activos',
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
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
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
//
// Jerarquía: nombre primero, luego wallet. Toda la card navega a los
// productos del artesano; editar/eliminar viven en el menú overflow y el
// switch controla el estado. Una sola familia de affordances.

class _ArtisanCard extends ConsumerWidget {
  final Artisan artisan;
  const _ArtisanCard({required this.artisan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isActive = artisan.isActive;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/admin/artisans/${artisan.id}/products',
          extra: artisan.name,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isActive ? null : Border.all(color: cs.outlineVariant),
          ),
          // Foto con tamaño fijo: dentro de un sliver la altura entrante es
          // infinita, así que nada aquí puede depender de stretch ni de
          // alturas intrínsecas (SizedBox.expand las reporta infinitas).
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: _ArtisanBanner(artisan: artisan),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              artisan.name,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (artisan.specialty.isNotEmpty ||
                                artisan.location.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (artisan.specialty.isNotEmpty)
                                    artisan.specialty,
                                  if (artisan.location.isNotEmpty)
                                    artisan.location,
                                ].join(' · '),
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 14,
                                  color: artisan.walletAddressUrl.isNotEmpty
                                      ? cs.primary
                                      : cs.error,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    artisan.walletAddressUrl.isNotEmpty
                                        ? artisan.walletAddressUrl
                                        : 'Sin wallet — no puede recibir pagos',
                                    style: tt.bodySmall?.copyWith(
                                      color: artisan.walletAddressUrl.isNotEmpty
                                          ? cs.onSurfaceVariant
                                          : cs.error,
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Semantics(
                            label: isActive
                                ? 'Desactivar a ${artisan.name}'
                                : 'Activar a ${artisan.name}',
                            child: Switch(
                              value: isActive,
                              onChanged: (_) => _toggleArtisan(context, ref),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Más opciones',
                            icon: Icon(
                              Icons.more_vert,
                              color: cs.onSurfaceVariant,
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  context.push(
                                    '/admin/artisans/${artisan.id}/edit',
                                  );
                                case 'delete':
                                  _confirmDelete(context, ref);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Editar'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete_outline,
                                    color: cs.error,
                                  ),
                                  title: Text(
                                    'Eliminar',
                                    style: TextStyle(color: cs.error),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  /// Ejecuta una mutación y comunica el resultado con un snackbar.
  Future<void> _run(
    BuildContext context,
    Future<String?> mutation,
    String successMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final error = await mutation;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? successMessage),
          backgroundColor: error != null ? errorColor : null,
        ),
      );
  }

  void _toggleArtisan(BuildContext context, WidgetRef ref) {
    final willActivate = !artisan.isActive;
    final verb = willActivate ? 'activar' : 'desactivar';
    final done = willActivate ? 'activado' : 'desactivado';
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
              _run(
                context,
                ref.read(artisansProvider.notifier).toggleActive(artisan.id),
                '${artisan.name} $done.',
              );
            },
            child: const Text('Solo el artesano'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _run(
                context,
                ref
                    .read(artisansProvider.notifier)
                    .toggleActive(artisan.id, cascade: true),
                '${artisan.name} y sus productos ${done}s.',
              );
            },
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
        content: Text(
          '¿Eliminar a ${artisan.name}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _run(
                context,
                ref.read(artisansProvider.notifier).delete(artisan.id),
                '${artisan.name} eliminado.',
              );
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
    final rawUrl = artisan.imageUrl;

    Widget content = rawUrl.isNotEmpty
        ? AppImage(
            '$baseUrl${imageVariant(rawUrl, 'thumb')}',
            fallbackUrl: '$baseUrl$rawUrl',
            cacheWidth: 200,
            errorIconSize: 24,
          )
        : _initialsBlock(initials, cs, tt);

    if (!artisan.isActive) {
      content = ColorFiltered(
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
          style: tt.headlineMedium?.copyWith(
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

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
      height: 96,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 96, color: block),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Rect(w: 140, h: 14, color: block),
                  const SizedBox(height: 8),
                  _Rect(w: 100, h: 10, color: block),
                  const Spacer(),
                  _Rect(w: 190, h: 10, color: block),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: _Rect(w: 44, h: 24, r: 12, color: block)),
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
