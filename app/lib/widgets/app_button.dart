import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final style = switch (variant) {
      AppButtonVariant.primary => _primaryStyle(cs),
      AppButtonVariant.secondary => _secondaryStyle(cs),
      AppButtonVariant.text => _textStyle(cs),
    };

    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: style.foregroundColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );

    if (variant == AppButtonVariant.text) {
      return TextButton(onPressed: onPressed, child: child);
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: style.backgroundColor,
        foregroundColor: style.foregroundColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: style.borderSide,
        ),
        minimumSize: const Size(0, 48),
      ),
      child: child,
    );
  }
}

class _ButtonStyle {
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide borderSide;
  const _ButtonStyle(this.backgroundColor, this.foregroundColor, this.borderSide);
}

_ButtonStyle _primaryStyle(ColorScheme cs) {
  return _ButtonStyle(
    cs.primary,
    cs.onPrimary,
    BorderSide.none,
  );
}

_ButtonStyle _secondaryStyle(ColorScheme cs) {
  return _ButtonStyle(
    cs.secondaryContainer,
    cs.onSecondaryContainer,
    BorderSide.none,
  );
}

_ButtonStyle _textStyle(ColorScheme cs) {
  return _ButtonStyle(
    Colors.transparent,
    cs.primary,
    BorderSide.none,
  );
}
