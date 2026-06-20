import 'package:openpayments_app/models/checkout.dart';
import 'package:openpayments_app/service/api_client.dart';

class CheckoutService {
  final ApiClient _api;
  CheckoutService(this._api);

  Future<CheckoutResponse> checkout(CheckoutRequest request) async {
    final json = await _api.post('/api/checkout', body: request.toJson());
    return CheckoutResponse.fromJson(json as Map<String, dynamic>);
  }
}
