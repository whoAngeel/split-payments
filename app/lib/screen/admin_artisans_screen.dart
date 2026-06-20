import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/widgets/app_scaffold.dart';

class AdminArtisansScreen extends ConsumerWidget {
  const AdminArtisansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outlined, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'Artesanos',
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
