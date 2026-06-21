import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/models/admin_product.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/widgets/app_empty_state.dart';

class AdminArtisanProductsScreen extends ConsumerStatefulWidget {
  final int artisanId;
  final String artisanName;
  const AdminArtisanProductsScreen({super.key, required this.artisanId, required this.artisanName});

  @override
  ConsumerState<AdminArtisanProductsScreen> createState() => _AdminArtisanProductsScreenState();
}

class _AdminArtisanProductsScreenState extends ConsumerState<AdminArtisanProductsScreen> {
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

    try {
      final service = ref.read(galleryServiceProvider);
      final products = await service.getArtisanProducts(session.galleryId, widget.artisanId);
      if (mounted) setState(() { _products = products; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleActive(AdminProduct product) async {
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) return;
    try {
      await ref.read(galleryServiceProvider).toggleProductActive(session.galleryId, product.id);
      _load();
    } catch (_) {}
  }

  Future<void> _delete(AdminProduct product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final session = ref.read(authProvider).valueOrNull;
    if (session == null) return;
    try {
      await ref.read(galleryServiceProvider).deleteProduct(session.galleryId, product.id);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Productos de ${widget.artisanName}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/admin/artisans/${widget.artisanId}/products/new');
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: cs.error)))
              : _products.isEmpty
                  ? const AppEmptyState(icon: Icons.inventory_2_outlined, title: 'Sin productos', description: 'Crea tu primer producto')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final p = _products[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: p.isActive ? cs.surface : cs.surfaceContainerHighest,
                            child: ListTile(
                              title: Text(p.name, style: TextStyle(fontWeight: FontWeight.w600, color: p.isActive ? cs.onSurface : cs.onSurfaceVariant)),
                              subtitle: Text('\$${(p.basePrice / 100).toStringAsFixed(2)} ${p.assetCode}', style: TextStyle(color: cs.onSurfaceVariant)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(value: p.isActive, onChanged: (_) => _toggleActive(p)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _delete(p),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
