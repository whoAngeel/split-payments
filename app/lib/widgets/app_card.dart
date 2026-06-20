import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pad = padding ?? const EdgeInsets.all(16);
    final mar = margin ?? EdgeInsets.zero;
    final hasBorder = border ?? false;

    return Padding(
      padding: mar,
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: pad,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: hasBorder
                  ? Border.all(color: cs.outline, width: 1)
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
