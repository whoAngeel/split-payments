import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/providers/admin_provider.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/widgets/app_error_state.dart';
import 'package:openpayments_app/widgets/app_button.dart';
import 'package:openpayments_app/widgets/app_card.dart';
import 'package:go_router/go_router.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _rateController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final commissionAsync = ref.watch(commissionProvider);

    return commissionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorState(
        message: 'No se pudo cargar la configuración',
        onRetry: () => ref.invalidate(commissionProvider),
      ),
      data: (rate) {
        if (_rateController.text.isEmpty) {
          _rateController.text = (rate / 100.0).toStringAsFixed(1);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Configuración',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasa de comisión',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Porcentaje aplicado al precio base de cada producto',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _rateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Porcentaje',
                              suffixText: '%',
                              border: OutlineInputBorder(),
                            ),
                            enabled: !_saving,
                          ),
                        ),
                        const SizedBox(width: 12),
                        AppButton(
                          label: 'Guardar',
                          onPressed: _saving ? null : _saveCommission,
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: cs.error)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuenta',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Cerrar sesión',
                      variant: AppButtonVariant.text,
                      fullWidth: true,
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCommission() async {
    final text = _rateController.text.trim();
    final value = double.tryParse(text);
    if (value == null || value < 0 || value > 100) {
      setState(() => _error = 'Ingresa un valor entre 0 y 100');
      return;
    }

    final rate = (value * 100).round();

    setState(() {
      _saving = true;
      _error = null;
    });

    await ref.read(commissionProvider.notifier).setCommission(rate);

    if (mounted) {
      setState(() => _saving = false);

      final state = ref.read(commissionProvider);
      if (state.hasError) {
        setState(() => _error = 'Error al guardar: ${state.error}');
      }
    }
  }
}
