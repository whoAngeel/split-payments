import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _nameController = TextEditingController();
  final _walletController = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull?.user;
    if (user != null) {
      _nameController.text = user.name;
      _walletController.text = user.walletAddressUrl;
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
    if (name.isEmpty) {
      setState(() => _error = 'El nombre no puede estar vacío');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      final service = ref.read(authServiceProvider);
      await service.updateMe(name: name, walletAddressUrl: _walletController.text.trim());

      // Refresh session
      final session = ref.read(authProvider).valueOrNull;
      if (session != null) {
        final updated = await service.me(session.token);
        ref.read(authProvider.notifier).updateSession(updated);
      }

      if (mounted) setState(() { _editing = false; _saving = false; });
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Error al guardar: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = ref.watch(authProvider).valueOrNull?.user;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Mi cuenta'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => setState(() { _editing = !_editing; _error = null; }),
            child: Text(_editing ? 'Cancelar' : 'Editar'),
          ),
          if (_editing)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 48,
              backgroundColor: cs.primaryContainer,
              child: Text(
                _initials(user?.name ?? ''),
                style: tt.headlineMedium?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? '', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            Text(user?.email ?? '', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 32),

            if (_editing) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _walletController,
                    decoration: const InputDecoration(labelText: 'Wallet URL', hintText: 'https://...', border: OutlineInputBorder()),
                    enabled: !_saving,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: cs.error)),
                  ],
                ]),
              ),
            ] else ...[
              _InfoRow(cs: cs, icon: Icons.email_outlined, label: 'Email', value: user?.email ?? ''),
              Divider(height: 1, indent: 56, color: cs.outlineVariant),
              _InfoRow(cs: cs, icon: Icons.account_balance_wallet_outlined, label: 'Wallet', value: user?.walletAddressUrl.isNotEmpty == true ? user!.walletAddressUrl : 'Sin wallet', muted: user?.walletAddressUrl.isEmpty ?? true),
            ],
            const SizedBox(height: 32),
            Divider(height: 1, color: cs.outlineVariant),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  final ColorScheme cs;
  final IconData icon;
  final String label;
  final String value;
  final bool muted;

  const _InfoRow({required this.cs, required this.icon, required this.label, required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: muted ? cs.onSurfaceVariant : cs.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: muted ? cs.onSurfaceVariant : cs.onSurface)),
            ]),
          ),
        ],
      ),
    );
  }
}
