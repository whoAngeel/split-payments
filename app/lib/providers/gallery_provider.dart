import 'dart:async';

import 'package:openpayments_app/models/product.dart';
import 'package:openpayments_app/models/product_detail.dart';
import 'package:riverpod/riverpod.dart';

import 'api_client_provider.dart';

final galleryProvider = AsyncNotifierProvider<GalleryNotifier, List<Product>>(
  GalleryNotifier.new,
);

final productDetailProvider = FutureProvider.family<ProductDetail, int>(
  (ref, id) async {
    final service = ref.read(galleryServiceProvider);
    return service.getProductDetail(id);
  },
);

class GalleryNotifier extends AsyncNotifier<List<Product>> {
  @override
  FutureOr<List<Product>> build() {
    final service = ref.read(galleryServiceProvider);
    return service.getProducts();
  }

  Future<void> refresh() async {
    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() => service.getProducts());
  }
}
