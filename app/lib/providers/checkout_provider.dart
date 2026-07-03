import '../models/checkout.dart';
import '../models/product.dart';
import 'api_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedProductProvider = StateProvider<Product?>((ref) => null);
final checkoutProvider =
    AsyncNotifierProvider<CheckoutNotifier, CheckoutResponse?>(
      CheckoutNotifier.new,
    );

class CheckoutNotifier extends AsyncNotifier<CheckoutResponse?> {
  @override
  Future<CheckoutResponse?> build() => Future.value(null);
  Future<void> checkout(CheckoutRequest request) async {
    final service = ref.read(checkoutServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => service.checkout(request));
  }

  void reset() => state = const AsyncData(null);
}
