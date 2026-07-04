import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openpayments_app/service/api_client.dart';
import 'package:openpayments_app/service/auth_service.dart';
import 'package:openpayments_app/service/checkout_service.dart';
import 'package:openpayments_app/service/gallery_service.dart';
import 'package:openpayments_app/service/logger_service.dart';
import '../config/app_config.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseURL: appConfig.baseUrl,
    logger: ref.read(loggerProvider),
  );
});

final galleryServiceProvider = Provider<GalleryService>((ref) {
  final api = ref.watch(apiClientProvider);
  final logger = ref.read(loggerProvider);
  return GalleryService(api, logger);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.watch(apiClientProvider);
  final logger = ref.read(loggerProvider);
  return AuthService(api, logger);
});

final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  final api = ref.watch(apiClientProvider);
  return CheckoutService(api);
});
