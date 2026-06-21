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

  Future<List<Product>> getProducts() async {
    final json = await _api.get('/api/explore/products');
    _logger.i('Explore response: $json');
    final list = json as List<dynamic>;
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
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
}
