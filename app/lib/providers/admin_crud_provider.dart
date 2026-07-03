import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/models/admin_product.dart';
import 'package:openpayments_app/models/artisan.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/providers/admin_provider.dart';
import 'package:openpayments_app/service/api_client.dart';

final artisansProvider = AsyncNotifierProvider<ArtisansNotifier, List<Artisan>>(
  ArtisansNotifier.new,
);

/// Convierte una excepción de mutación en un mensaje para el usuario.
/// Nunca expone el error crudo.
String _friendlyError(Object e, String fallback) {
  if (e is ApiException) {
    if (e.statusCode == 409) {
      return 'No se puede completar: el artesano todavía tiene productos.';
    }
    if (e.statusCode >= 500) {
      return 'El servidor no respondió bien. Intenta de nuevo en un momento.';
    }
  }
  return fallback;
}

class ArtisansNotifier extends AsyncNotifier<List<Artisan>> {
  int get _galleryId => ref.read(authProvider).valueOrNull?.galleryId ?? 0;

  @override
  Future<List<Artisan>> build() async {
    if (_galleryId == 0) return [];
    return ref.read(galleryServiceProvider).getArtisans(_galleryId);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(galleryServiceProvider).getArtisans(_galleryId),
    );
  }

  /// Ejecuta una mutación y recarga la lista. Devuelve `null` si todo salió
  /// bien o un mensaje de error amigable. La lista actual se conserva si la
  /// mutación falla (un toggle fallido no debe tumbar toda la pantalla).
  Future<String?> _mutate(
    Future<void> Function() action,
    String fallbackError,
  ) async {
    final service = ref.read(galleryServiceProvider);
    try {
      await action();
    } catch (e) {
      return _friendlyError(e, fallbackError);
    }
    state = await AsyncValue.guard(() => service.getArtisans(_galleryId));
    ref.invalidate(dashboardProvider);
    return null;
  }

  Future<String?> create(
    String name,
    String walletAddressUrl, {
    String imageUrl = '',
    String bio = '',
    String location = '',
    String specialty = '',
    String craftType = '',
    String tags = '',
  }) {
    final service = ref.read(galleryServiceProvider);
    return _mutate(
      () => service.createArtisan(
        _galleryId,
        name,
        walletAddressUrl,
        imageUrl: imageUrl,
        bio: bio,
        location: location,
        specialty: specialty,
        craftType: craftType,
        tags: tags,
      ),
      'No se pudo crear el artesano. Verifica tu conexión e intenta de nuevo.',
    );
  }

  Future<String?> updateArtisan(
    int artisanId, {
    String? name,
    String? walletAddressUrl,
    String? imageUrl,
    String? bio,
    String? location,
    String? specialty,
    String? craftType,
    String? tags,
  }) {
    final service = ref.read(galleryServiceProvider);
    return _mutate(
      () => service.updateArtisan(
        _galleryId,
        artisanId,
        name: name,
        walletAddressUrl: walletAddressUrl,
        imageUrl: imageUrl,
        bio: bio,
        location: location,
        specialty: specialty,
        craftType: craftType,
        tags: tags,
      ),
      'No se pudieron guardar los cambios. Intenta de nuevo.',
    );
  }

  Future<String?> toggleActive(int artisanId, {bool cascade = false}) async {
    final service = ref.read(galleryServiceProvider);
    final error = await _mutate(
      () =>
          service.toggleArtisanActive(_galleryId, artisanId, cascade: cascade),
      'No se pudo cambiar el estado del artesano. Intenta de nuevo.',
    );
    if (error == null) ref.invalidate(adminProductsProvider);
    return error;
  }

  Future<String?> delete(int artisanId) {
    final service = ref.read(galleryServiceProvider);
    return _mutate(
      () => service.deleteArtisan(_galleryId, artisanId),
      'No se pudo eliminar el artesano. Intenta de nuevo.',
    );
  }
}

final adminProductsProvider =
    AsyncNotifierProvider<AdminProductsNotifier, List<AdminProduct>>(
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
    state = await AsyncValue.guard(
      () => ref.read(galleryServiceProvider).getAdminProducts(_galleryId),
    );
  }

  /// Igual que en [ArtisansNotifier._mutate]: la lista sobrevive a una
  /// mutación fallida y el error vuelve como mensaje amigable.
  Future<String?> _mutate(
    Future<void> Function() action,
    String fallbackError,
  ) async {
    final service = ref.read(galleryServiceProvider);
    try {
      await action();
    } catch (e) {
      return _friendlyError(e, fallbackError);
    }
    state = await AsyncValue.guard(() => service.getAdminProducts(_galleryId));
    ref.invalidate(dashboardProvider);
    return null;
  }

  Future<String?> create(
    int artisanId,
    String name,
    int basePrice,
    String assetCode, {
    int assetScale = 2,
    String imageUrl = '',
    int commissionRate = 0,
    String description = '',
    String materials = '',
    String dimensions = '',
    String tags = '',
  }) {
    final service = ref.read(galleryServiceProvider);
    return _mutate(
      () => service.createProduct(
        _galleryId,
        artisanId,
        name: name,
        basePrice: basePrice,
        assetCode: assetCode,
        assetScale: assetScale,
        imageUrl: imageUrl,
        commissionRate: commissionRate,
        description: description,
        materials: materials,
        dimensions: dimensions,
        tags: tags,
      ),
      'No se pudo crear el producto. Verifica tu conexión e intenta de nuevo.',
    );
  }

  Future<String?> updateProduct(
    int productId, {
    String? name,
    int? basePrice,
    String? imageUrl,
    int? commissionRate,
    String? description,
    String? materials,
    String? dimensions,
    String? tags,
  }) {
    final service = ref.read(galleryServiceProvider);
    return _mutate(
      () => service.updateProduct(
        _galleryId,
        productId,
        name: name,
        basePrice: basePrice,
        imageUrl: imageUrl,
        commissionRate: commissionRate,
        description: description,
        materials: materials,
        dimensions: dimensions,
        tags: tags,
      ),
      'No se pudieron guardar los cambios. Intenta de nuevo.',
    );
  }

  Future<String?> toggleActive(int productId) {
    final service = ref.read(galleryServiceProvider);
    return _mutate(
      () => service.toggleProductActive(_galleryId, productId),
      'No se pudo cambiar el estado del producto. Intenta de nuevo.',
    );
  }

  Future<String?> delete(int productId) {
    final service = ref.read(galleryServiceProvider);
    return _mutate(
      () => service.deleteProduct(_galleryId, productId),
      'No se pudo eliminar el producto. Intenta de nuevo.',
    );
  }
}
