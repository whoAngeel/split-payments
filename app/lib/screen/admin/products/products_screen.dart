import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/models/artisan.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/widgets/admin_product_card.dart';
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

  Future<void> _toggle(int productId) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final error = await ref
        .read(adminProductsProvider.notifier)
        .toggleActive(productId);
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error), backgroundColor: errorColor),
        );
    }
  }

  /// Crear producto requiere elegir artesano: bottom sheet con la lista y
  /// navegación directa al form de producto de ese artesano.
  Future<void> _pickArtisanAndCreate() async {
    final artisans = ref.read(artisansProvider).valueOrNull ?? [];
    if (artisans.isEmpty) {
      await ref.read(artisansProvider.notifier).refresh();
    }
    if (!mounted) return;
    final available = (ref.read(artisansProvider).valueOrNull ?? []).toList();

    if (available.isEmpty) {
      final goCreate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Primero necesitas un artesano'),
          content: const Text(
            'Cada producto pertenece a un artesano. Crea uno para continuar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Crear artesano'),
            ),
          ],
        ),
      );
      if (goCreate == true && mounted) context.push('/admin/artisans/new');
      return;
    }

    final artisan = await showModalBottomSheet<Artisan>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '¿De qué artesano es el producto?',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (_, i) {
                  final a = available[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        ctx,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(a.name),
                    subtitle: a.isActive ? null : const Text('Inactivo'),
                    onTap: () => Navigator.pop(ctx, a),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (artisan == null || !mounted) return;
    await context.push('/admin/artisans/${artisan.id}/products/new');
    if (mounted) ref.read(adminProductsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final productsAsync = ref.watch(adminProductsProvider);
    final baseUrl = ref.read(apiClientProvider).baseUrl;

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: _pickArtisanAndCreate,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        tooltip: 'Nuevo producto',
        child: const Icon(Icons.add),
      ),
      body: productsAsync.when(
        loading: () => const AdminProductSkeletonList(),
        error: (_, __) => AppErrorState(
          message: 'No se pudieron cargar los productos.',
          onRetry: () => ref.invalidate(adminProductsProvider),
        ),
        data: (products) {
          if (products.isEmpty) {
            return AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Sin productos',
              description:
                  'Agrega el primer producto de tu galería para empezar a vender.',
              actionLabel: 'Crear producto',
              onAction: _pickArtisanAndCreate,
            );
          }

          final active = products.where((p) => p.isActive).length;

          return RefreshIndicator(
            onRefresh: () => ref.read(adminProductsProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        Text(
                          'Productos',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                        ),
                        const SizedBox(width: 10),
                        _CountPill(active: active, total: products.length),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => AdminProductCard(
                      product: products[i],
                      baseUrl: baseUrl,
                      onToggle: () => _toggle(products[i].id),
                      onTap: () =>
                          context.push('/admin/products/${products[i].id}'),
                    ),
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
        '$active de $total activos',
        style: tt.labelSmall?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
