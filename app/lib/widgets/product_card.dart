import 'package:flutter/material.dart';

import 'app_card.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.name,
    required this.artisanName,
    required this.price,
    this.imageUrl,
    this.baseUrl,
    this.assetCode = 'USD',
    this.onTap,
  });

  final String name;
  final String artisanName;
  final int price;
  final String? imageUrl;
  final String? baseUrl;
  final String assetCode;
  final VoidCallback? onTap;

  String? get _resolvedUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return imageUrl;
    }
    if (baseUrl != null && imageUrl!.startsWith('/')) {
      return '$baseUrl$imageUrl';
    }
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _resolvedUrl;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image area
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: url != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, _, _) => _imagePlaceholder(cs),
                    ),
                  )
                : _imagePlaceholder(cs),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  artisanName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatPrice(price, assetCode),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme cs) {
    return Center(
      child: Icon(Icons.image_outlined, size: 48, color: cs.outline),
    );
  }

  String _formatPrice(int cents, String code) {
    final dollars = cents / 100;
    if (dollars == dollars.roundToDouble()) {
      return '\$${dollars.toStringAsFixed(0)} $code';
    }
    return '\$${dollars.toStringAsFixed(2)} $code';
  }
}
