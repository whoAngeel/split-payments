import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/models/artisan.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
import 'package:openpayments_app/widgets/app_empty_state.dart';
import 'package:openpayments_app/widgets/app_error_state.dart';

class AdminArtisansScreen extends ConsumerWidget {
  const AdminArtisansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artisansAsync = ref.watch(artisansProvider);

    return artisansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorState(
        message: 'Error al cargar artesanos',
        onRetry: () => ref.invalidate(artisansProvider),
      ),
      data: (artisans) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/admin/artisans/new'),
            child: const Icon(Icons.add),
          ),
          body: artisans.isEmpty
              ? AppEmptyState(
                  icon: Icons.people_outlined,
                  title: 'Sin artesanos',
                  description: 'Crea tu primer artesano',
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(artisansProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: artisans.length,
                    itemBuilder: (context, index) {
                      final artisan = artisans[index];
                      return _ArtisanListTile(artisan: artisan);
                    },
                  ),
                ),
        );
      },
    );
  }
}

class _ArtisanListTile extends ConsumerWidget {
  final Artisan artisan;
  const _ArtisanListTile({required this.artisan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: artisan.isActive ? cs.surface : cs.surfaceContainerHighest,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(Icons.person, color: cs.onPrimaryContainer),
        ),
        title: Text(
          artisan.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: artisan.isActive ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          artisan.walletAddressUrl.isNotEmpty ? artisan.walletAddressUrl : 'Sin wallet',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: artisan.isActive,
              onChanged: (_) => _toggleArtisan(context, ref),
            ),
            PopupMenuButton<String>(
              onSelected: (action) => _onAction(action, context, ref),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(value: 'products', child: Text('Ver productos')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        onTap: () => context.push('/admin/artisans/${artisan.id}/products', extra: artisan.name),
      ),
    );
  }

  void _toggleArtisan(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Toggle cascada'),
        content: const Text('¿Aplicar cambio a todos los productos del artesano?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(artisansProvider.notifier).toggleActive(artisan.id, cascade: true);
            },
            child: const Text('Con productos'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(artisansProvider.notifier).toggleActive(artisan.id);
            },
            child: const Text('Solo artesano'),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar artesano'),
        content: Text('¿Eliminar a ${artisan.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(artisansProvider.notifier).delete(artisan.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
