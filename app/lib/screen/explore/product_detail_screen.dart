import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product.dart';
import '../../models/product_detail.dart';
import '../../providers/gallery_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/api_client_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(productDetailProvider(productId));

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(elevation: 0, scrolledUnderElevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(elevation: 0, scrolledUnderElevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Could not load product.\nPlease try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
      data: (detail) => _DetailBody(detail: detail),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  final ProductDetail detail;

  const _DetailBody({required this.detail});

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  int _pageIndex = 0;
  late final PageController _pageController;

  ProductDetail get detail => widget.detail;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final price = detail.basePrice / pow(10, detail.assetScale);
    final baseUrl = ref.read(apiClientProvider).baseUrl;
    final allImages = [detail.imageUrl, ...detail.images];

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: false,
            automaticallyImplyLeading: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _ImageGallery(
                images: allImages,
                pageIndex: _pageIndex,
                controller: _pageController,
                onPageChanged: (i) => setState(() => _pageIndex = i),
                cs: cs,
                baseUrl: baseUrl,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.tags.isNotEmpty) ...[
                    _Tags(tags: detail.tags, cs: cs),
                    const SizedBox(height: 12),
                  ],
                  _Header(detail: detail, price: price),
                  const SizedBox(height: 20),
                  if (detail.materials.isNotEmpty || detail.dimensions.isNotEmpty) ...[
                    _Specs(detail: detail, cs: cs),
                    const SizedBox(height: 20),
                  ],
                  if (detail.split != null) ...[
                    _PaymentTransparency(
                      split: detail.split!,
                      basePrice: detail.basePrice,
                      assetCode: detail.assetCode,
                      assetScale: detail.assetScale,
                      cs: cs,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (detail.description.isNotEmpty) ...[
                    _Description(detail: detail, cs: cs),
                    const SizedBox(height: 28),
                  ],
                  Divider(height: 1, color: cs.outlineVariant),
                  const SizedBox(height: 24),
                  _ArtisanRow(detail: detail, cs: cs),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: () {
              ref.read(selectedProductProvider.notifier).state = Product(
                id: detail.id,
                name: detail.name,
                basePrice: detail.basePrice,
                assetCode: detail.assetCode,
                assetScale: detail.assetScale,
                artisanName: detail.artisan.name,
                imageUrl: detail.imageUrl,
                split: detail.split,
              );
              context.push('/checkout');
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.inverseSurface,
              foregroundColor: cs.onInverseSurface,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payments_outlined, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Buy with Open Payments',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.onInverseSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${detail.assetCode} ${price.toStringAsFixed(detail.assetScale)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.inversePrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final int pageIndex;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final ColorScheme cs;
  final String baseUrl;

  const _ImageGallery({
    required this.images,
    required this.pageIndex,
    required this.controller,
    required this.onPageChanged,
    required this.cs,
    this.baseUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          controller: controller,
          itemCount: images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return images[index].isNotEmpty
                ? Image.network(
                    images[index].startsWith('http') ? images[index] : '$baseUrl${images[index]}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder();
          },
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == pageIndex ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == pageIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.image_outlined, size: 64, color: cs.outline),
      ),
    );
  }
}

class _Tags extends StatelessWidget {
  final List<String> tags;
  final ColorScheme cs;

  const _Tags({required this.tags, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '#$tag',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Header extends StatelessWidget {
  final ProductDetail detail;
  final num price;

  const _Header({required this.detail, required this.price});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.artisan.name,
          style: tt.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          detail.name,
          style: tt.headlineMedium?.copyWith(
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${detail.assetCode} ${price.toStringAsFixed(detail.assetScale)}',
          style: tt.titleLarge?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _Specs extends StatelessWidget {
  final ProductDetail detail;
  final ColorScheme cs;

  const _Specs({required this.detail, required this.cs});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasBoth = detail.materials.isNotEmpty && detail.dimensions.isNotEmpty;

    if (!hasBoth) {
      final label = detail.materials.isNotEmpty ? 'Materials' : 'Dimensions';
      final value = detail.materials.isNotEmpty ? detail.materials : detail.dimensions;
      return _specCell(tt, label, value);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _specCell(tt, 'Materials', detail.materials)),
        const SizedBox(width: 20),
        Expanded(child: _specCell(tt, 'Dimensions', detail.dimensions)),
      ],
    );
  }

  Widget _specCell(TextTheme tt, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
      ],
    );
  }
}

class _PaymentTransparency extends StatelessWidget {
  final ProductSplit split;
  final int basePrice;
  final String assetCode;
  final int assetScale;
  final ColorScheme cs;

  const _PaymentTransparency({
    required this.split,
    required this.basePrice,
    required this.assetCode,
    required this.assetScale,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scale = pow(10, assetScale);
    final artisanAmt = basePrice * split.artisanPercent / 100 / scale;
    final galleryAmt = basePrice * split.galleryPercent / 100 / scale;
    final platformAmt = basePrice * split.platformPercent / 100 / scale;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'PAYMENT TRANSPARENCY',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
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
          const SizedBox(height: 12),
          _splitRow(
            context,
            cs.primary,
            'Artisan direct',
            artisanAmt,
            split.artisanPercent,
          ),
          if (split.galleryPercent > 0) ...[
            const SizedBox(height: 8),
            _splitRow(
              context,
              cs.onSurfaceVariant,
              'Gallery',
              galleryAmt,
              split.galleryPercent,
            ),
          ],
          if (split.platformPercent > 0) ...[
            const SizedBox(height: 8),
            _splitRow(
              context,
              cs.tertiary,
              'Plataforma',
              platformAmt,
              split.platformPercent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _splitRow(
    BuildContext context,
    Color dotColor,
    String label,
    double amount,
    int percent,
  ) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface)),
        ),
        Text(
          '$assetCode ${amount.toStringAsFixed(assetScale)} ($percent%)',
          style: tt.bodySmall?.copyWith(
            color: dotColor == cs.primary ? cs.primary : cs.onSurfaceVariant,
            fontWeight: dotColor == cs.primary ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _Description extends StatelessWidget {
  final ProductDetail detail;
  final ColorScheme cs;

  const _Description({required this.detail, required this.cs});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          detail.description,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _ArtisanRow extends StatelessWidget {
  final ProductDetail detail;
  final ColorScheme cs;

  const _ArtisanRow({required this.detail, required this.cs});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final initials = _initials(detail.artisan.name);
    final hasBio = detail.artisan.bio.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: cs.primaryContainer,
          backgroundImage: detail.artisan.imageUrl.isNotEmpty
              ? NetworkImage(detail.artisan.imageUrl)
              : null,
          child: detail.artisan.imageUrl.isEmpty
              ? Text(
                  initials,
                  style: tt.titleMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.artisan.name,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (hasBio) ...[
                const SizedBox(height: 6),
                Text(
                  '"${detail.artisan.bio}"',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
