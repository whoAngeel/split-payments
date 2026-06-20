import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/widgets/app_scaffold.dart';

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'Productos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
