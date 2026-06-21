import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/providers/admin_crud_provider.dart';

class AdminArtisanFormScreen extends ConsumerStatefulWidget {
  final int? artisanId;
  const AdminArtisanFormScreen({super.key, this.artisanId});

  @override
  ConsumerState<AdminArtisanFormScreen> createState() => _AdminArtisanFormScreenState();
}

class _AdminArtisanFormScreenState extends ConsumerState<AdminArtisanFormScreen> {
  final _nameController = TextEditingController();
  final _walletController = TextEditingController();
  bool _saving = false;
  String? _error;
  bool get _isEdit => widget.artisanId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadArtisan();
    }
  }

  void _loadArtisan() {
    final artisans = ref.read(artisansProvider).valueOrNull ?? [];
    final artisan = artisans.where((a) => a.id == widget.artisanId).firstOrNull;
    if (artisan != null) {
      _nameController.text = artisan.name;
      _walletController.text = artisan.walletAddressUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _walletController.dispose();
    super.dispose();
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
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar artesano' : 'Nuevo artesano'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _walletController,
              decoration: const InputDecoration(
                labelText: 'Wallet Address URL',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
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
                child: Text(_isEdit ? 'Guardar cambios' : 'Crear artesano'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
