import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, label) = switch (status) {
      'completed' => (cs.primaryContainer, cs.onPrimaryContainer, 'Completed'),
      'pending' => (cs.secondaryContainer, cs.onSecondaryContainer, 'Pending'),
      'failed' => (cs.errorContainer, cs.onErrorContainer, 'Failed'),
      _ => (cs.surfaceContainerHighest, cs.onSurfaceVariant, _capitalize(status)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
