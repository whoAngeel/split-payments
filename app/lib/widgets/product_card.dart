import 'dart:math';

import 'package:flutter/material.dart';

import '../models/product.dart';
import 'app_card.dart';
import 'split_payment_bar.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onBuy;
  final VoidCallback? onFavorite;

  const ProductCard({
    super.key,
    required this.product,
    this.onBuy,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppCard(
      onTap: onBuy,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _imageSection(cs),
          _contentSection(cs, tt),
        ],
      ),
    );
  }

  Widget _imageSection(ColorScheme cs) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(cs),
                    ),
                  )
                : _placeholder(cs),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white.withValues(alpha: 0.8),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onFavorite,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    product.isFavorited ? Icons.favorite : Icons.favorite_outline,
                    size: 20,
                    color: product.isFavorited ? Colors.red : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentSection(ColorScheme cs, TextTheme tt) {
    final price = product.basePrice / pow(10, product.assetScale);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            product.name,
            style: tt.titleMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            product.artisanName,
            style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${product.assetCode} ${price.toStringAsFixed(product.assetScale)}',
            style: tt.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (product.split != null) ...[
            const SizedBox(height: 10),
            SplitPaymentBar(split: product.split!),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onBuy,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Buy with Open Payments'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Center(
      child: Icon(Icons.image_outlined, size: 40, color: cs.outline),
    );
  }
}
