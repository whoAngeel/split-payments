import 'dart:math';

import 'package:flutter/material.dart';

import '../models/product.dart';
import 'app_card.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onBuy;
  final VoidCallback? onFavorite;
  final String baseUrl;

  const ProductCard({
    super.key,
    required this.product,
    this.onBuy,
    this.onFavorite,
    this.baseUrl = '',
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
          _ImageSection(product: product, cs: cs, onFavorite: onFavorite, baseUrl: baseUrl),
          _ContentSection(product: product, cs: cs, tt: tt, onBuy: onBuy),
        ],
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  final Product product;
  final ColorScheme cs;
  final VoidCallback? onFavorite;
  final String baseUrl;

  const _ImageSection({
    required this.product,
    required this.cs,
    required this.onFavorite,
    this.baseUrl = '',
  });

  @override
  Widget build(BuildContext context) {
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
                      product.imageUrl.startsWith('http') ? product.imageUrl : '$baseUrl${product.imageUrl}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  )
                : _placeholder(),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _FavoriteButton(
              isFavorited: product.isFavorited,
              onTap: onFavorite,
              cs: cs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(Icons.image_outlined, size: 40, color: cs.outline),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorited;
  final VoidCallback? onTap;
  final ColorScheme cs;

  const _FavoriteButton({
    required this.isFavorited,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            isFavorited ? Icons.favorite : Icons.favorite_outline,
            size: 20,
            color: isFavorited ? cs.error : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  final Product product;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback? onBuy;

  const _ContentSection({
    required this.product,
    required this.cs,
    required this.tt,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final price = product.basePrice / pow(10, product.assetScale);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            product.artisanName,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            product.name,
            style: tt.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${product.assetCode} ${price.toStringAsFixed(product.assetScale)}',
            style: tt.titleMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onBuy,
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: const Text('Buy with Open Payments'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.inverseSurface,
                foregroundColor: cs.onInverseSurface,
                textStyle: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
