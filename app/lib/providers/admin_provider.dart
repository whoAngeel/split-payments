import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/models/gallery_dashboard.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/providers/auth_provider.dart';

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, GalleryDashboard?>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<GalleryDashboard?> {
  @override
  Future<GalleryDashboard?> build() async {
    final session = ref.read(authProvider).valueOrNull;
    if (session == null || !session.isAdmin) return null;

    final service = ref.read(galleryServiceProvider);
    return service.getDashboard(session.galleryId);
  }

  Future<void> refresh() async {
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) return;

    final service = ref.read(galleryServiceProvider);
    state = await AsyncValue.guard(() => service.getDashboard(session.galleryId));
  }
}
