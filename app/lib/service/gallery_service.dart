import 'package:openpayments_app/models/product.dart';
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
}
