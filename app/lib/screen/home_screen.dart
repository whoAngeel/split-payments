import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/widgets/app_button.dart';

import '../widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(title: const Text('OpenPayments')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'OpenPayments',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Artesanal \u00b7 C\u00e1lido \u00b7 Confiable',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Ver productos',
              onPressed: () {
                context.go('/explorar');
              },
            ),
          ],
        ),
      ),
    );
  }
}
