import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/widgets/app_scaffold.dart';
import 'package:openpayments_app/widgets/app_button.dart';
import 'package:go_router/go_router.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_outlined, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'Ajustes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Cerrar sesion',
              variant: AppButtonVariant.text,
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
