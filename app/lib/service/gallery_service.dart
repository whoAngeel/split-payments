import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:openpayments_app/models/admin_product.dart';
import 'package:openpayments_app/models/artisan.dart';
import 'package:openpayments_app/models/gallery_dashboard.dart';
import 'package:openpayments_app/models/payment.dart';
import 'package:openpayments_app/models/product.dart';
import 'package:openpayments_app/models/product_detail.dart';
import 'package:openpayments_app/service/api_client.dart';
import 'package:openpayments_app/service/logger_service.dart';

class GalleryService {
  final ApiClient _api;
  final AppLogger _logger;

  GalleryService(this._api, this._logger);

  Future<Map<String, dynamic>> uploadImage(
    File file, {
    String prefix = 'uploads',
  }) async {
    final uri = Uri.parse('${_api.baseUrl}/api/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${_api.token}';
    request.fields['prefix'] = prefix;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<List<Product>> getProducts({int cursor = 0, int limit = 20}) async {
    final json = await _api.get('/api/explore/products?cursor=$cursor&limit=$limit');
    final data = json as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>;
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getExplorePage({int cursor = 0, int limit = 20}) async {
    final json = await _api.get('/api/explore/products?cursor=$cursor&limit=$limit');
    return json as Map<String, dynamic>;
  }

  Future<ProductDetail> getProductDetail(int id) async {
    final json = await _api.get('/api/explore/products/$id');
    return ProductDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Payment>> getPayments() async {
    final json = await _api.get('/api/payments');
    final list = json as List<dynamic>;
    return list
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GalleryPayments> getGalleryPayments(int galleryId) async {
    final json = await _api.get('/api/galleries/$galleryId/payments');
    return GalleryPayments.fromJson(json as Map<String, dynamic>);
  }

  Future<GalleryDashboard> getDashboard(int galleryId) async {
    final json = await _api.get('/api/galleries/$galleryId');
    return GalleryDashboard.fromJson(json as Map<String, dynamic>);
  }

  Future<void> setCommission(int galleryId, int rate) async {
    await _api.put(
      '/api/galleries/$galleryId/commission',
      body: {'rate': rate},
    );
  }

  // Artisans

  Future<Map<String, dynamic>> getArtisansPage(int galleryId, {int page = 1, int limit = 20}) async {
    final json = await _api.get('/api/galleries/$galleryId/artisans?page=$page&limit=$limit');
    return json as Map<String, dynamic>;
  }

  Future<List<Artisan>> getArtisans(int galleryId, {int page = 1, int limit = 20}) async {
    final data = await getArtisansPage(galleryId, page: page, limit: limit);
    final list = data['items'] as List<dynamic>;
    return list.map((e) => Artisan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Artisan> createArtisan(
    int galleryId,
    String name,
    String walletAddressUrl, {
    String imageUrl = '',
    String bio = '',
    String location = '',
    String specialty = '',
    String craftType = '',
    String tags = '',
  }) async {
    final json = await _api.post(
      '/api/galleries/$galleryId/artisans',
      body: {
        'name': name,
        'wallet_address_url': walletAddressUrl,
        if (imageUrl.isNotEmpty) 'image_url': imageUrl,
        if (bio.isNotEmpty) 'bio': bio,
        if (location.isNotEmpty) 'location': location,
        if (specialty.isNotEmpty) 'specialty': specialty,
        if (craftType.isNotEmpty) 'craft_type': craftType,
        if (tags.isNotEmpty) 'tags': tags,
      },
    );
    return Artisan.fromJson(json as Map<String, dynamic>);
  }

  Future<Artisan> updateArtisan(
    int galleryId,
    int artisanId, {
    String? name,
    String? walletAddressUrl,
    String? imageUrl,
    String? bio,
    String? location,
    String? specialty,
    String? craftType,
    String? tags,
  }) async {
    final json = await _api.patch(
      '/api/galleries/$galleryId/artisans/$artisanId',
      body: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (walletAddressUrl != null && walletAddressUrl.isNotEmpty)
          'wallet_address_url': walletAddressUrl,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        if (bio != null && bio.isNotEmpty) 'bio': bio,
        if (location != null && location.isNotEmpty) 'location': location,
        if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
        if (craftType != null && craftType.isNotEmpty) 'craft_type': craftType,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      },
    );
    return Artisan.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteArtisan(int galleryId, int artisanId) async {
    await _api.delete('/api/galleries/$galleryId/artisans/$artisanId');
  }

  Future<Artisan> toggleArtisanActive(
    int galleryId,
    int artisanId, {
    bool cascade = false,
  }) async {
    final path = cascade
        ? '/api/galleries/$galleryId/artisans/$artisanId/toggle-active?cascade=true'
        : '/api/galleries/$galleryId/artisans/$artisanId/toggle-active';
    final json = await _api.post(path);
    return Artisan.fromJson(json as Map<String, dynamic>);
  }

  Future<Artisan> getArtisan(int galleryId, int artisanId) async {
    final json = await _api.get(
      '/api/galleries/$galleryId/artisans/$artisanId',
    );
    return Artisan.fromJson(json as Map<String, dynamic>);
  }

  // Products

  Future<List<AdminProduct>> getAdminProducts(int galleryId, {int page = 1, int limit = 20}) async {
    final json = await _api.get('/api/galleries/$galleryId/products?page=$page&limit=$limit');
    final data = json as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>;
    return list
        .map((e) => AdminProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminProduct>> getArtisanProducts(
    int galleryId,
    int artisanId,
  ) async {
    final json = await _api.get(
      '/api/galleries/$galleryId/artisans/$artisanId/products',
    );
    final list = json as List<dynamic>;
    return list
        .map((e) => AdminProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminProduct> createProduct(
    int galleryId,
    int artisanId, {
    required String name,
    required int basePrice,
    required String assetCode,
    int assetScale = 2,
    String imageUrl = '',
    int commissionRate = 0,
    String description = '',
    String materials = '',
    String dimensions = '',
    String tags = '',
  }) async {
    final json = await _api.post(
      '/api/galleries/$galleryId/artisans/$artisanId/products',
      body: {
        'name': name,
        'base_price': basePrice,
        'asset_code': assetCode,
        'asset_scale': assetScale,
        'image_url': imageUrl,
        'commission_rate': commissionRate,
        if (description.isNotEmpty) 'description': description,
        if (materials.isNotEmpty) 'materials': materials,
        if (dimensions.isNotEmpty) 'dimensions': dimensions,
        if (tags.isNotEmpty) 'tags': tags,
      },
    );
    return AdminProduct.fromJson(json as Map<String, dynamic>);
  }

  Future<AdminProduct> updateProduct(
    int galleryId,
    int productId, {
    String? name,
    int? basePrice,
    String? imageUrl,
    int? commissionRate,
    String? description,
    String? materials,
    String? dimensions,
    String? tags,
  }) async {
    final json = await _api.patch(
      '/api/galleries/$galleryId/products/$productId',
      body: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (basePrice != null && basePrice > 0) 'base_price': basePrice,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        if (commissionRate != null && commissionRate >= 0)
          'commission_rate': commissionRate,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (materials != null && materials.isNotEmpty) 'materials': materials,
        if (dimensions != null && dimensions.isNotEmpty)
          'dimensions': dimensions,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      },
    );
    return AdminProduct.fromJson(json as Map<String, dynamic>);
  }

  Future<AdminProduct> getAdminProductDetail(
    int galleryId,
    int productId,
  ) async {
    final json = await _api.get(
      '/api/galleries/$galleryId/products/$productId',
    );
    return AdminProduct.fromDetailJson(json as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getProductImages(
    int galleryId,
    int productId,
  ) async {
    final json = await _api.get(
      '/api/galleries/$galleryId/products/$productId/images',
    );
    return (json as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> addProductImage(
    int galleryId,
    int productId,
    String imageUrl,
  ) async {
    final json = await _api.post(
      '/api/galleries/$galleryId/products/$productId/images',
      body: {'image_url': imageUrl},
    );
    return json as Map<String, dynamic>;
  }

  Future<void> deleteProductImage(
    int galleryId,
    int productId,
    int imageId,
  ) async {
    await _api.delete(
      '/api/galleries/$galleryId/products/$productId/images/$imageId',
    );
  }

  Future<void> deleteProduct(int galleryId, int productId) async {
    await _api.delete('/api/galleries/$galleryId/products/$productId');
  }

  Future<AdminProduct> toggleProductActive(int galleryId, int productId) async {
    final json = await _api.post(
      '/api/galleries/$galleryId/products/$productId/toggle-active',
    );
    return AdminProduct.fromJson(json as Map<String, dynamic>);
  }
}
