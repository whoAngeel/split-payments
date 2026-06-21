import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/providers/auth_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final int artisanId;
  final int? productId;
  const ProductFormScreen({super.key, required this.artisanId, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _commissionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _materialsController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _tagsController = TextEditingController();
  final _imageController = TextEditingController();
  bool _saving = false;
  bool _uploading = false;
  String? _error;
  String? _previewUrl;
  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadProduct();
  }

  void _loadProduct() async {
    final galleryId = ref.read(authProvider).valueOrNull?.galleryId ?? 0;
    if (galleryId == 0) return;
    try {
      final service = ref.read(galleryServiceProvider);
      final product = await service.getAdminProductDetail(galleryId, widget.productId!);
      if (mounted) {
        _nameController.text = product.name;
        _priceController.text = (product.basePrice / 100).toStringAsFixed(2);
        _commissionController.text = product.commissionPercent.toStringAsFixed(1);
        _descriptionController.text = product.description;
        _materialsController.text = product.materials;
        _dimensionsController.text = product.dimensions;
        _tagsController.text = product.tags;
        _imageController.text = product.imageUrl;
        if (product.imageUrl.isNotEmpty) setState(() => _previewUrl = product.imageUrl);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _commissionController.dispose();
    _descriptionController.dispose();
    _materialsController.dispose();
    _dimensionsController.dispose();
    _tagsController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _uploadImage() async {
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

    setState(() => _uploading = true);
    try {
      final service = ref.read(galleryServiceProvider);
      final result = await service.uploadImage(File(xfile.path), prefix: 'products');
      final url = result['medium_url'] as String? ?? '';
      _imageController.text = url;
      setState(() => _previewUrl = url);
    } catch (e) {
      setState(() => _error = 'Error al subir imagen: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final commissionText = _commissionController.text.trim();

    if (name.isEmpty || priceText.isEmpty || commissionText.isEmpty) {
      setState(() => _error = 'Nombre, precio y comisión son requeridos');
      return;
    }

    final price = (double.parse(priceText) * 100).round();
    final commission = (double.parse(commissionText) * 100).round();

    setState(() { _saving = true; _error = null; });

    if (_isEdit) {
      await ref.read(adminProductsProvider.notifier).updateProduct(
        widget.productId!,
        name: name,
        basePrice: price,
        imageUrl: _imageController.text.trim(),
        commissionRate: commission,
        description: _descriptionController.text.trim(),
        materials: _materialsController.text.trim(),
        dimensions: _dimensionsController.text.trim(),
        tags: _tagsController.text.trim(),
      );
    } else {
      await ref.read(adminProductsProvider.notifier).create(
        widget.artisanId, name, price, 'USD',
        imageUrl: _imageController.text.trim(),
        commissionRate: commission,
        description: _descriptionController.text.trim(),
        materials: _materialsController.text.trim(),
        dimensions: _dimensionsController.text.trim(),
        tags: _tagsController.text.trim(),
      );
    }

    if (mounted) {
      final state = ref.read(adminProductsProvider);
      if (state.hasError) {
        setState(() { _saving = false; _error = 'Error: ${state.error}'; });
      } else {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseUrl = ref.read(apiClientProvider).baseUrl;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar producto' : 'Nuevo producto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildField('Nombre *', _nameController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 3, child: _buildField('Precio * (\$)', _priceController, keyboardType: TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildField('Comisión * (%)', _commissionController, keyboardType: TextInputType.numberWithOptions(decimal: true))),
            ],
          ),
          const SizedBox(height: 12),
          _buildField('Descripción', _descriptionController, maxLines: 3),
          const SizedBox(height: 12),
          _buildField('Materiales', _materialsController),
          const SizedBox(height: 12),
          _buildField('Dimensiones', _dimensionsController),
          const SizedBox(height: 12),
          _buildField('Tags (separados por coma)', _tagsController),
          const SizedBox(height: 24),
          _ImagePreview(url: _previewUrl, baseUrl: baseUrl, uploading: _uploading, onUpload: _uploadImage),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _saving ? null : _save, child: Text(_isEdit ? 'Guardar cambios' : 'Crear producto'))),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      enabled: !_saving,
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String? url;
  final String baseUrl;
  final bool uploading;
  final VoidCallback onUpload;
  const _ImagePreview({this.url, required this.baseUrl, required this.uploading, required this.onUpload});

  String? get _fullUrl => url != null && url!.isNotEmpty ? '$baseUrl$url' : null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity, height: 200,
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outlineVariant)),
          clipBehavior: Clip.antiAlias,
          child: uploading
              ? const Center(child: CircularProgressIndicator())
              : url != null && url!.isNotEmpty
                  ? Image.network(_fullUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.broken_image_outlined, size: 48, color: cs.onSurfaceVariant), const SizedBox(height: 8), Text('Error al cargar', style: TextStyle(color: cs.onSurfaceVariant))])))
                  : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.image_outlined, size: 48, color: cs.onSurfaceVariant), const SizedBox(height: 8), Text('Sin imagen', style: TextStyle(color: cs.onSurfaceVariant))])),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: uploading ? null : onUpload, icon: const Icon(Icons.cloud_upload_outlined, size: 18), label: Text(url != null && url!.isNotEmpty ? 'Cambiar imagen' : 'Subir imagen')),
      ],
    );
  }
}
