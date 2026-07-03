import 'package:openpayments_app/models/checkout.dart';
import 'package:openpayments_app/service/api_client.dart';

class CheckoutService {
  final ApiClient _api;
  CheckoutService(this._api);

  Future<CheckoutResponse> checkout(CheckoutRequest request) async {
    final json = await _api.post('/api/checkout', body: request.toJson());
    return CheckoutResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<void> savePayment(String sessionId, int productId, int buyerId) async {
    await _api.post('/api/checkout/save', body: {
      'session_id': sessionId,
      'product_id': productId,
      'buyer_id': buyerId,
    });
  }

  Future<void> completePayment(String sessionId, {String status = 'completed'}) async {
    await _api.post('/api/checkout/complete', body: {
      'session_id': sessionId,
      'status': status,
    });
  }
}
