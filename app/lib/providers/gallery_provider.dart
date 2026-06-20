import 'dart:async';

import 'package:openpayments_app/models/product.dart';
import 'package:riverpod/riverpod.dart';

import 'api_client_provider.dart';

final galleryProvider = AsyncNotifierProvider<GalleryNotifier, List<Product>>(
  GalleryNotifier.new,
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
