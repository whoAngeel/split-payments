import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/models/admin_product.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/widgets/admin_product_card.dart';
import 'package:openpayments_app/widgets/app_empty_state.dart';
import 'package:openpayments_app/widgets/app_error_state.dart';

class AdminArtisanProductsScreen extends ConsumerStatefulWidget {
  final int artisanId;
  final String artisanName;
  const AdminArtisanProductsScreen({
    super.key,
    required this.artisanId,
    required this.artisanName,
  });

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
        setState(
          () => _error =
              'No se pudieron cargar los productos. Verifica tu conexión e intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggle(AdminProduct p) async {
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) return;
    try {
      await ref
          .read(galleryServiceProvider)
          .toggleProductActive(session.galleryId, p.id);
      // La lista global de productos comparte estado con esta vista.
      ref.invalidate(adminProductsProvider);
      await _load();
    } catch (_) {
      _showSnack(
        'No se pudo cambiar el estado de "${p.name}". Intenta de nuevo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseUrl = ref.read(apiClientProvider).baseUrl;

    Widget body;

    if (_loading) {
      body = const AdminProductSkeletonList();
    } else if (_error != null) {
      body = AppErrorState(message: _error!, onRetry: _load);
    } else if (_products.isEmpty) {
      body = AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Sin productos',
        description: 'Crea el primer producto de ${widget.artisanName}.',
        actionLabel: 'Crear producto',
        onAction: () async {
          await context.push(
            '/admin/artisans/${widget.artisanId}/products/new',
          );
          _load();
        },
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
                itemBuilder: (_, i) => AdminProductCard(
                  product: _products[i],
                  baseUrl: baseUrl,
                  showArtisan: false,
                  onToggle: () => _toggle(_products[i]),
                  onTap: () async {
                    await context.push('/admin/products/${_products[i].id}');
                    _load();
                  },
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
          await context.push(
            '/admin/artisans/${widget.artisanId}/products/new',
          );
          _load();
        },
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        tooltip: 'Nuevo producto',
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}
