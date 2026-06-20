import 'package:flutter/material.dart';

import '../models/product.dart';

class SplitPaymentBar extends StatelessWidget {
  final ProductSplit split;
  final bool compact;

  const SplitPaymentBar({
    super.key,
    required this.split,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Split Payment Breakdown',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const Spacer(),
            Text(
              '${split.artisanPercent}% to Artisan',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                if (split.artisanPercent > 0)
                  Expanded(
                    flex: split.artisanPercent,
                    child: Container(color: cs.primary),
                  ),
                if (split.galleryPercent > 0)
                  Expanded(
                    flex: split.galleryPercent,
                    child: Container(color: cs.secondary),
                  ),
                if (split.platformPercent > 0)
                  Expanded(
                    flex: split.platformPercent,
                    child: Container(color: cs.tertiary),
                  ),
              ],
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _legendDot(cs, cs.primary, 'Artisan', Theme.of(context).textTheme),
              _legendDot(cs, cs.secondary, 'Gallery', Theme.of(context).textTheme),
              if (split.platformPercent > 0)
                _legendDot(cs, cs.tertiary, 'Platform', Theme.of(context).textTheme),
            ],
          ),
        ],
      ],
    );
  }

  Widget _legendDot(ColorScheme cs, Color color, String label, TextTheme textTheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
