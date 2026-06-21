import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/models/admin_product.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
import 'package:openpayments_app/widgets/app_empty_state.dart';
import 'package:openpayments_app/widgets/app_error_state.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProductsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final cs = Theme.of(context).colorScheme;

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorState(
        message: 'Error al cargar productos',
        onRetry: () => ref.invalidate(adminProductsProvider),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Sin productos',
            description: 'Crea productos desde la vista de artesanos',
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(adminProductsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: p.isActive ? cs.surface : cs.surfaceContainerHighest,
                child: ListTile(
                  title: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: p.isActive ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(
                    '${p.artisanName} · \$${(p.basePrice / 100).toStringAsFixed(2)} ${p.assetCode} · ${p.commissionPercent.toStringAsFixed(1)}%',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: p.isActive,
                        onChanged: (_) => _toggleActive(ref, p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, p),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _toggleActive(WidgetRef ref, AdminProduct p) {
    ref.read(adminProductsProvider.notifier).toggleActive(p.id);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AdminProduct p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar ${p.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminProductsProvider.notifier).delete(p.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
