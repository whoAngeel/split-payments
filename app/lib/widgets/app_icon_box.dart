import 'package:flutter/material.dart';

class AppIconBox extends StatelessWidget {
  const AppIconBox({
    super.key,
    required this.icon,
    this.size = 64,
    this.radius = 16,
    this.color,
  });

  final IconData icon;
  final double size;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = color ?? cs.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: iconColor, size: size * 0.45),
    );
  }
}
