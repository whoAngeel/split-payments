import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openpayments_app/utils/image_utils.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/widgets/app_image.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final int artisanId;
  final int? productId;
  const ProductFormScreen({super.key, required this.artisanId, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
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
      final product = await service.getAdminProductDetail(
        galleryId,
        widget.productId!,
      );
      if (mounted) {
        _nameController.text = product.name;
        _priceController.text = (product.basePrice / 100).toStringAsFixed(2);
        _commissionController.text = product.commissionPercent.toStringAsFixed(
          1,
        );
        _descriptionController.text = product.description;
        _materialsController.text = product.materials;
        _dimensionsController.text = product.dimensions;
        _tagsController.text = product.tags;
        _imageController.text = product.imageUrl;
        if (product.imageUrl.isNotEmpty)
          setState(() => _previewUrl = product.imageUrl);
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
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
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
      final fixed = await fixExifOrientation(File(xfile.path));
      final result = await service.uploadImage(
        fixed,
        prefix: 'products',
      );
      final url = result['medium_url'] as String? ?? '';
      _imageController.text = url;
      setState(() => _previewUrl = url);
    } catch (_) {
      setState(() => _error = 'No se pudo subir la imagen. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final priceValue = double.parse(_priceController.text.trim());
    final commissionValue = double.parse(_commissionController.text.trim());

    final price = (priceValue * 100).round();
    final commission = (commissionValue * 100).round();

    setState(() {
      _saving = true;
      _error = null;
    });

    final String? error;
    if (_isEdit) {
      error = await ref
          .read(adminProductsProvider.notifier)
          .updateProduct(
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
      error = await ref
          .read(adminProductsProvider.notifier)
          .create(
            widget.artisanId,
            name,
            price,
            'USD',
            imageUrl: _imageController.text.trim(),
            commissionRate: commission,
            description: _descriptionController.text.trim(),
            materials: _materialsController.text.trim(),
            dimensions: _dimensionsController.text.trim(),
            tags: _tagsController.text.trim(),
          );
    }

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Cambios guardados.' : 'Producto creado.'),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseUrl = ref.read(apiClientProvider).baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField(
              'Nombre *',
              _nameController,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'El nombre es requerido';
                if (value.length < 2) return 'Mínimo 2 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildField(
                    'Precio * (\$)',
                    _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final value = double.tryParse(v?.trim() ?? '');
                      if (value == null) return 'Precio requerido';
                      if (value <= 0) return 'Debe ser mayor a 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildField(
                    'Comisión * (%)',
                    _commissionController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,1}'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final value = double.tryParse(v?.trim() ?? '');
                      if (value == null) return 'Requerida';
                      if (value < 0 || value > 100) return 'Entre 0 y 100';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SplitPreview(
              commissionText: _commissionController.text,
              priceText: _priceController.text,
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
            _ImagePreview(
              url: _previewUrl,
              baseUrl: baseUrl,
              uploading: _uploading,
              onUpload: _uploadImage,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: cs.error)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Guardar cambios' : 'Crear producto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      enabled: !_saving,
    );
  }
}

/// Preview en vivo de cómo se reparte el pago según la comisión capturada.
/// Responde a la pregunta "¿cuánto le queda al artesano?" antes de guardar.
class _SplitPreview extends StatelessWidget {
  final String commissionText;
  final String priceText;

  const _SplitPreview({required this.commissionText, required this.priceText});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final commission = double.tryParse(commissionText.trim());
    if (commission == null || commission < 0 || commission > 100) {
      return const SizedBox.shrink();
    }

    final galleryPct = commission.round().clamp(0, 100);
    final artisanPct = (100 - galleryPct).clamp(0, 100);
    final price = double.tryParse(priceText.trim());

    String amountFor(int pct) {
      if (price == null || price <= 0) return '';
      return ' · \$${(price * pct / 100).toStringAsFixed(2)}';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Así se reparte cada venta',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(
              children: [
                if (artisanPct > 0)
                  Expanded(
                    flex: artisanPct,
                    child: Container(height: 6, color: cs.primary),
                  ),
                if (galleryPct > 0)
                  Expanded(
                    flex: galleryPct,
                    child: Container(height: 6, color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Artesano $artisanPct%${amountFor(artisanPct)}',
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Galería $galleryPct%${amountFor(galleryPct)}',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String? url;
  final String baseUrl;
  final bool uploading;
  final VoidCallback onUpload;
  const _ImagePreview({
    this.url,
    required this.baseUrl,
    required this.uploading,
    required this.onUpload,
  });

  String? get _fullUrl =>
      url != null && url!.isNotEmpty ? '$baseUrl$url' : null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: uploading
              ? const Center(child: CircularProgressIndicator())
              : url != null && url!.isNotEmpty
              ? AppImage(_fullUrl!, cacheWidth: 1000, errorIconSize: 48)
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sin imagen',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: uploading ? null : onUpload,
          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
          label: Text(
            url != null && url!.isNotEmpty ? 'Cambiar imagen' : 'Subir imagen',
          ),
        ),
      ],
    );
  }
}
