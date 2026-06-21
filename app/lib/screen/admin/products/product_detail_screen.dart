import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openpayments_app/models/admin_product.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';

class AdminProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;
  const AdminProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<AdminProductDetailScreen> createState() => _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends ConsumerState<AdminProductDetailScreen> {
  AdminProduct? _product;
  List<Map<String, dynamic>> _images = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int get _galleryId => ref.read(authProvider).valueOrNull?.galleryId ?? 0;
  String get _baseUrl => ref.read(apiClientProvider).baseUrl;

  Future<void> _load() async {
    if (_galleryId == 0) return;
    try {
      final service = ref.read(galleryServiceProvider);
      final product = await service.getAdminProductDetail(_galleryId, widget.productId);
      final images = await service.getProductImages(_galleryId, widget.productId);
      if (mounted) setState(() { _product = product; _images = images; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _getUrl(dynamic img) => (img['image_url'] as String?) ?? '';
  int _getId(dynamic img) => (img['id'] as num).toInt();

  Future<void> _addImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Tomar foto'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Seleccionar de galería'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 80);
    if (xfile == null) return;

    try {
      final service = ref.read(galleryServiceProvider);
      final result = await service.uploadImage(File(xfile.path), prefix: 'products');
      final url = result['medium_url'] as String? ?? '';
      await service.addProductImage(_galleryId, widget.productId, url);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteImage(int imageId) async {
    try {
      final service = ref.read(galleryServiceProvider);
      await service.deleteProductImage(_galleryId, widget.productId, imageId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Eliminar producto'), content: const Text('Esta acción no se puede deshacer'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar'))],
    ));
    if (confirm != true) return;
    try {
      await ref.read(galleryServiceProvider).deleteProduct(_galleryId, widget.productId);
      ref.invalidate(adminProductsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Producto')), body: const Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Producto')), body: Center(child: Text(_error!, style: TextStyle(color: cs.error))));

    final p = _product!;
    final isActive = p.isActive;

    return Scaffold(
      appBar: AppBar(title: Text(p.name), actions: [
        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () async {
          await context.push('/admin/products/${widget.productId}/edit');
          _load();
        }),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _deleteProduct),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main image
          if (p.imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network('$_baseUrl${p.imageUrl}', height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
          ],

          // Price + commission
          Row(children: [
            Expanded(child: _InfoCard(icon: Icons.attach_money, label: 'Precio', value: '\$${(p.basePrice / 100).toStringAsFixed(2)} USD')),
            const SizedBox(width: 12),
            Expanded(child: _InfoCard(icon: Icons.percent, label: 'Comisión', value: '${p.commissionPercent.toStringAsFixed(1)}%')),
          ]),
          const SizedBox(height: 12),
          if (!isActive) _Badge('Inactivo', cs.error),
          const SizedBox(height: 16),

          // Detail fields
          _buildSection(tt, cs, 'Descripción', p.description),
          _buildSection(tt, cs, 'Materiales', p.materials),
          _buildSection(tt, cs, 'Dimensiones', p.dimensions),
          _buildSection(tt, cs, 'Tags', p.tags),

          const SizedBox(height: 24),

          // Images gallery
          Text('Imágenes', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ..._images.map((img) => Stack(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network('$_baseUrl${_getUrl(img)}', width: 100, height: 100, fit: BoxFit.cover)),
                  Positioned(top: 2, right: 2, child: GestureDetector(onTap: () => _deleteImage(_getId(img)), child: Container(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(2), child: const Icon(Icons.close, size: 16, color: Colors.white)))),
                ],
              )),
              _AddImageButton(onTap: _addImage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(TextTheme tt, ColorScheme cs, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [Icon(icon, size: 18, color: cs.primary), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)), Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))])]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text; final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)));
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 100, height: 100, decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8), border: Border.all(color: cs.outlineVariant, style: BorderStyle.solid)), child: Icon(Icons.add, color: cs.onSurfaceVariant)),
    );
  }
}
