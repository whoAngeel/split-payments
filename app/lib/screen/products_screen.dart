import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/config/app_config.dart';
import 'package:openpayments_app/providers/gallery_provider.dart';
import 'package:openpayments_app/widgets/product_card.dart';

import '../widgets/app_chip.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(galleryProvider);

    return productsAsync.when(
      error: (err, stackTrace) => Center(child: Text('Error: $err')),
      loading: () => const Center(child: CircularProgressIndicator()),
      data: (products) => RefreshIndicator(
        onRefresh: () => ref.read(galleryProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const AppChip(label: 'Todos', selected: true),
                      const SizedBox(width: 8),
                      AppChip(label: 'Ceramica', onTap: () {}),
                      const SizedBox(width: 8),
                      AppChip(label: 'Textil', onTap: () {}),
                      const SizedBox(width: 8),
                      AppChip(label: 'Madera', onTap: () {}),
                      const SizedBox(width: 8),
                      AppChip(label: 'Metal', onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index];
                    return ProductCard(
                      name: product.name,
                      artisanName: product.artisanName,
                      price: product.basePrice,
                      imageUrl: product.imageUrl,
                      baseUrl: appConfig.baseUrl,
                      onTap: () {},
                    );
                  },
                  childCount: products.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
