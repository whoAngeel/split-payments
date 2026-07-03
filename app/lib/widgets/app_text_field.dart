import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.validator,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.autofocus = false,
    this.enabled = true,
  });

  final String? label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      validator: validator,
      autofocus: autofocus,
      enabled: enabled,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: cs.onSurface,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _border(cs.outline, 12),
        enabledBorder: _border(cs.outline, 12),
        focusedBorder: _border(cs.primary, 12),
        errorBorder: _border(cs.error, 12),
        focusedErrorBorder: _border(cs.error, 12),
        labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
        errorStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.error,
            ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, double radius) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: 1),
    );
  }
}
