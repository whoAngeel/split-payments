import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/models/payment.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/providers/auth_provider.dart';

final paymentsProvider = AsyncNotifierProvider<PaymentsNotifier, List<Payment>>(
  PaymentsNotifier.new,
);

class PaymentsNotifier extends AsyncNotifier<List<Payment>> {
  @override
  Future<List<Payment>> build() async {
    ref.watch(authProvider);
    final service = ref.read(galleryServiceProvider);
    return service.getPayments();
  }

  Future<void> refresh() async {
    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() => service.getPayments());
  }
}

/// Pagos de la galería del operador (vista admin), con resumen agregado.
final galleryPaymentsProvider =
    AsyncNotifierProvider<GalleryPaymentsNotifier, GalleryPayments>(
      GalleryPaymentsNotifier.new,
    );

class GalleryPaymentsNotifier extends AsyncNotifier<GalleryPayments> {
  int get _galleryId => ref.read(authProvider).valueOrNull?.galleryId ?? 0;

  @override
  Future<GalleryPayments> build() async {
    ref.watch(authProvider);
    if (_galleryId == 0) {
      return const GalleryPayments(
        summary: GalleryPaymentsSummary(),
        payments: [],
      );
    }
    return ref.read(galleryServiceProvider).getGalleryPayments(_galleryId);
  }

  Future<void> refresh() async {
    if (_galleryId == 0) return;
    state = await AsyncValue.guard(
      () => ref.read(galleryServiceProvider).getGalleryPayments(_galleryId),
    );
  }
}
