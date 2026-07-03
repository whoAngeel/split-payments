import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/widgets/app_image.dart';

class AdminArtisanFormScreen extends ConsumerStatefulWidget {
  final int? artisanId;
  const AdminArtisanFormScreen({super.key, this.artisanId});

  @override
  ConsumerState<AdminArtisanFormScreen> createState() =>
      _AdminArtisanFormScreenState();
}

class _AdminArtisanFormScreenState
    extends ConsumerState<AdminArtisanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _walletController = TextEditingController();
  final _imageController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _craftTypeController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _saving = false;
  bool _uploading = false;
  String? _error;
  String? _previewUrl;
  bool get _isEdit => widget.artisanId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadArtisan();
  }

  void _loadArtisan() {
    final artisans = ref.read(artisansProvider).valueOrNull ?? [];
    final artisan = artisans.where((a) => a.id == widget.artisanId).firstOrNull;
    if (artisan != null) {
      _nameController.text = artisan.name;
      _walletController.text = artisan.walletAddressUrl;
      _imageController.text = artisan.imageUrl;
      _bioController.text = artisan.bio;
      _locationController.text = artisan.location;
      _specialtyController.text = artisan.specialty;
      _craftTypeController.text = artisan.craftType;
      _tagsController.text = artisan.tags;
      if (artisan.imageUrl.isNotEmpty) _previewUrl = artisan.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _walletController.dispose();
    _imageController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _specialtyController.dispose();
    _craftTypeController.dispose();
    _tagsController.dispose();
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
      final result = await service.uploadImage(
        File(xfile.path),
        prefix: 'artisans',
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
    final wallet = _walletController.text.trim();

    setState(() {
      _saving = true;
      _error = null;
    });

    final String? error;
    if (_isEdit) {
      error = await ref
          .read(artisansProvider.notifier)
          .updateArtisan(
            widget.artisanId!,
            name: name,
            walletAddressUrl: wallet,
            imageUrl: _imageController.text.trim(),
            bio: _bioController.text.trim(),
            location: _locationController.text.trim(),
            specialty: _specialtyController.text.trim(),
            craftType: _craftTypeController.text.trim(),
            tags: _tagsController.text.trim(),
          );
    } else {
      error = await ref
          .read(artisansProvider.notifier)
          .create(
            name,
            wallet,
            imageUrl: _imageController.text.trim(),
            bio: _bioController.text.trim(),
            location: _locationController.text.trim(),
            specialty: _specialtyController.text.trim(),
            craftType: _craftTypeController.text.trim(),
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
          content: Text(_isEdit ? 'Cambios guardados.' : 'Artesano creado.'),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar artesano' : 'Nuevo artesano'),
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
            _buildField(
              'Wallet del artesano *',
              _walletController,
              hint: 'https://wallet.example.com/artesano',
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) {
                  return 'La wallet es requerida para recibir pagos';
                }
                if (!value.startsWith('https://')) {
                  return 'Debe empezar con https://';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildField('Ubicación (ej: Oaxaca, México)', _locationController),
            const SizedBox(height: 12),
            _buildField(
              'Especialidad (ej: Textiles, Cerámica)',
              _specialtyController,
            ),
            const SizedBox(height: 12),
            _buildField('Tipo de artesanía', _craftTypeController),
            const SizedBox(height: 12),
            _buildField('Biografía', _bioController, maxLines: 3),
            const SizedBox(height: 12),
            _buildField('Tags (separados por coma)', _tagsController),
            const SizedBox(height: 24),

            // Image preview + upload
            _ImagePreview(
              url: _previewUrl,
              baseUrl: ref.read(apiClientProvider).baseUrl,
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
                    : Text(_isEdit ? 'Guardar cambios' : 'Crear artesano'),
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
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      enabled: !_saving,
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
