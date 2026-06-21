import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/models/admin_product.dart';
import 'package:openpayments_app/models/artisan.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/providers/admin_provider.dart';

final artisansProvider = AsyncNotifierProvider<ArtisansNotifier, List<Artisan>>(
  ArtisansNotifier.new,
);

class ArtisansNotifier extends AsyncNotifier<List<Artisan>> {
  int get _galleryId => ref.read(authProvider).valueOrNull?.galleryId ?? 0;

  @override
  Future<List<Artisan>> build() async {
    if (_galleryId == 0) return [];
    return ref.read(galleryServiceProvider).getArtisans(_galleryId);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(galleryServiceProvider).getArtisans(_galleryId));
  }

  Future<void> create(String name, String walletAddressUrl) async {
    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() async {
      await service.createArtisan(_galleryId, name, walletAddressUrl);
      return service.getArtisans(_galleryId);
    });
    ref.invalidate(dashboardProvider);
  }

  Future<void> updateArtisan(int artisanId, {String? name, String? walletAddressUrl, String? imageUrl, String? bio}) async {
    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() async {
      await service.updateArtisan(_galleryId, artisanId, name: name, walletAddressUrl: walletAddressUrl, imageUrl: imageUrl, bio: bio);
      return service.getArtisans(_galleryId);
    });
  }

  Future<void> toggleActive(int artisanId, {bool cascade = false}) async {
    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() async {
      await service.toggleArtisanActive(_galleryId, artisanId, cascade: cascade);
      return service.getArtisans(_galleryId);
    });
    ref.invalidate(dashboardProvider);
    ref.invalidate(adminProductsProvider);
  }

  Future<void> delete(int artisanId) async {
    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() async {
      await service.deleteArtisan(_galleryId, artisanId);
      return service.getArtisans(_galleryId);
    });
    ref.invalidate(dashboardProvider);
  }
}

final adminProductsProvider = AsyncNotifierProvider<AdminProductsNotifier, List<AdminProduct>>(
  AdminProductsNotifier.new,
);

class AdminProductsNotifier extends AsyncNotifier<List<AdminProduct>> {
  int get _galleryId => ref.read(authProvider).valueOrNull?.galleryId ?? 0;

  @override
  Future<List<AdminProduct>> build() async {
    if (_galleryId == 0) return [];
    return ref.read(galleryServiceProvider).getAdminProducts(_galleryId);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(galleryServiceProvider).getAdminProducts(_galleryId));
  }

  Future<void> create(int artisanId, String name, int basePrice, String assetCode, {int assetScale = 2, String imageUrl = '', int commissionRate = 0}) async {
    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() async {
      await service.createProduct(_galleryId, artisanId, name: name, basePrice: basePrice, assetCode: assetCode, assetScale: assetScale, imageUrl: imageUrl, commissionRate: commissionRate);
      return service.getAdminProducts(_galleryId);
    });
    ref.invalidate(dashboardProvider);
  }

  Future<void> updateProduct(int productId, {String? name, int? basePrice, String? imageUrl, int? commissionRate}) async {
    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() async {
      await service.updateProduct(_galleryId, productId, name: name, basePrice: basePrice, imageUrl: imageUrl, commissionRate: commissionRate);
      return service.getAdminProducts(_galleryId);
    });
  }

  Future<void> toggleActive(int productId) async {
    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() async {
      await service.toggleProductActive(_galleryId, productId);
      return service.getAdminProducts(_galleryId);
    });
    ref.invalidate(dashboardProvider);
  }

  Future<void> delete(int productId) async {
    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() async {
      await service.deleteProduct(_galleryId, productId);
      return service.getAdminProducts(_galleryId);
    });
    ref.invalidate(dashboardProvider);
  }
}
