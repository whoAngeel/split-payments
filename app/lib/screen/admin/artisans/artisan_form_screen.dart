import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';

class AdminArtisanFormScreen extends ConsumerStatefulWidget {
  final int? artisanId;
  const AdminArtisanFormScreen({super.key, this.artisanId});

  @override
  ConsumerState<AdminArtisanFormScreen> createState() => _AdminArtisanFormScreenState();
}

class _AdminArtisanFormScreenState extends ConsumerState<AdminArtisanFormScreen> {
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
      final result = await service.uploadImage(File(xfile.path), prefix: 'artisans');
      _imageController.text = result['medium_url'] as String? ?? '';
    } catch (e) {
      setState(() => _error = 'Error al subir imagen: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final wallet = _walletController.text.trim();

    if (name.isEmpty || wallet.isEmpty) {
      setState(() => _error = 'Nombre y wallet son requeridos');
      return;
    }

    setState(() { _saving = true; _error = null; });

    if (_isEdit) {
      await ref.read(artisansProvider.notifier).updateArtisan(
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
      await ref.read(artisansProvider.notifier).create(name, wallet);
    }

    if (mounted) {
      final state = ref.read(artisansProvider);
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

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar artesano' : 'Nuevo artesano')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildField('Nombre *', _nameController),
          const SizedBox(height: 12),
          _buildField('Wallet Address URL *', _walletController),
          const SizedBox(height: 12),
          // Image URL with upload button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildField('Imagen URL', _imageController)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: IconButton.filled(
                  onPressed: _uploading ? null : _uploadImage,
                  icon: _uploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload_outlined),
                  tooltip: 'Subir imagen',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildField('Ubicación (ej: Oaxaca, México)', _locationController),
          const SizedBox(height: 12),
          _buildField('Especialidad (ej: Textiles, Cerámica)', _specialtyController),
          const SizedBox(height: 12),
          _buildField('Tipo de artesanía', _craftTypeController),
          const SizedBox(height: 12),
          _buildField('Biografía', _bioController, maxLines: 3),
          const SizedBox(height: 12),
          _buildField('Tags (separados por coma)', _tagsController),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: cs.error)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEdit ? 'Guardar cambios' : 'Crear artesano'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      enabled: !_saving,
    );
  }
}
