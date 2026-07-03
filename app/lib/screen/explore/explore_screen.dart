import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product.dart';
import '../../providers/gallery_provider.dart';
import '../../providers/api_client_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/app_chip.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(galleryProvider);

    return productsAsync.when(
      loading: () => const _ExploreLoading(),
      error: (err, _) => _ExploreError(err.toString()),
      data: (products) => _ExploreContent(products: products),
    );
  }
}

class _ExploreLoading extends StatelessWidget {
  const _ExploreLoading();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _headerSliver(context),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _ProductSkeleton(),
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductSkeleton extends StatelessWidget {
  const _ProductSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 180,
                  color: cs.surfaceContainerHigh,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  color: cs.surfaceContainerHigh,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  color: cs.surfaceContainerHigh,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreError extends StatelessWidget {
  final String message;
  const _ExploreError(this.message);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Error loading products',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreContent extends ConsumerStatefulWidget {
  final List<Product> products;
  const _ExploreContent({required this.products});

  @override
  ConsumerState<_ExploreContent> createState() => _ExploreContentState();
}

class _ExploreContentState extends ConsumerState<_ExploreContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _locations = [];
  List<String> _specialties = [];
  String? _selectedLocation;
  String? _selectedSpecialty;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final service = ref.read(galleryServiceProvider);
      final opts = await service.getFilterOptions();
      if (mounted) setState(() {
        _locations = (opts['locations'] as List<dynamic>?)?.cast<String>() ?? [];
        _specialties = (opts['specialties'] as List<dynamic>?)?.cast<String>() ?? [];
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return widget.products;
    return widget.products.where((p) {
      return p.name.toLowerCase().contains(_searchQuery) ||
          p.artisanName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredProducts;

    return RefreshIndicator(
      onRefresh: () => ref.read(galleryProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          _headerSliver(context),
          SliverToBoxAdapter(child: _searchAndFilters(context, cs)),
          if (filtered.isEmpty && _searchQuery.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No results for "$_searchQuery"',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProductCard(
                      product: product,
                      baseUrl: ref.read(apiClientProvider).baseUrl,
                  onBuy: () {
                    context.push('/product/${product.id}');
                  },
                    ),
                  );
                }, childCount: filtered.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _searchAndFilters(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search artworks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppChip(
                  label: 'Todos',
                  selected: _selectedSpecialty == null && _selectedLocation == null,
                  onTap: () => setState(() { _selectedSpecialty = null; _selectedLocation = null; }),
                ),
                ..._specialties.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: AppChip(
                    label: s,
                    selected: _selectedSpecialty == s,
                    onTap: () => setState(() {
                      _selectedSpecialty = _selectedSpecialty == s ? null : s;
                      _selectedLocation = null;
                    }),
                  ),
                )),
              ],
            ),
          ),
          if (_locations.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _locations.map((l) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: AppChip(
                    label: l,
                    selected: _selectedLocation == l,
                    onTap: () => setState(() {
                      _selectedLocation = _selectedLocation == l ? null : l;
                      _selectedSpecialty = null;
                    }),
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _headerSliver(BuildContext context) {
  final cs = Theme.of(context).colorScheme;

  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
            tooltip: 'Menu',
          ),
          const Spacer(),
          Text(
            'OAXACA ARTISAN',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => GoRouter.of(context).push('/account'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: cs.surfaceContainerHighest,
              child: Icon(
                Icons.person_outlined,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
