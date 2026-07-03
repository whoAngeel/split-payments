import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/models/gallery_dashboard.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/providers/auth_provider.dart';

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, GalleryDashboard?>(
      DashboardNotifier.new,
    );

class DashboardNotifier extends AsyncNotifier<GalleryDashboard?> {
  @override
  Future<GalleryDashboard?> build() async {
    // watch, no read: al cambiar de sesión el provider se reconstruye y
    // no queda dashboard de la cuenta anterior en memoria.
    final session = ref.watch(authProvider).valueOrNull;
    if (session == null || !session.isAdmin) return null;

    final service = ref.read(galleryServiceProvider);
    return service.getDashboard(session.galleryId);
  }

  Future<void> refresh() async {
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) return;

    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(
      () => service.getDashboard(session.galleryId),
    );
  }
}

final statsProvider = AsyncNotifierProvider<StatsNotifier, Map<String, dynamic>>(
  StatsNotifier.new,
);

class StatsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final session = ref.watch(authProvider).valueOrNull;
    if (session == null || !session.isAdmin) return {};

    final service = ref.read(galleryServiceProvider);
    return service.getDashboardStats(session.galleryId);
  }

  Future<void> refresh() async {
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) return;

    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() => service.getDashboardStats(session.galleryId));
  }
}
