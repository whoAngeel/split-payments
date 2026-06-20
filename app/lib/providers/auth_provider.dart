import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:openpayments_app/models/session.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/service/logger_service.dart';
import 'package:riverpod/riverpod.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, Session?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) return null;

    final api = ref.read(apiClientProvider);
    api.token = token;

    try {
      final user = await ref.read(authServiceProvider).me();
      return Session(token: token, user: user);
    } catch (_) {
      await storage.delete(key: 'token');
      api.token = null;
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    final service = ref.read(authServiceProvider);
    final api = ref.read(apiClientProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await service.login(email, password);
      api.token = session.token;
      await const FlutterSecureStorage().write(
        key: 'token',
        value: session.token,
      );
      return session;
    });
    if (state case AsyncError(:final error, :final stackTrace)) {
      ref
          .read(loggerProvider)
          .e('Login failed', error: error, stackTrace: stackTrace);
    }
  }

  void cancelLogin() {
    state = const AsyncData(null);
  }

  Future<void> register(String email, String password, String name, {String? walletAddress}) async {
    final service = ref.read(authServiceProvider);
    final api = ref.read(apiClientProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await service.register(email, password, name, walletAddress: walletAddress);
      api.token = session.token;
      await const FlutterSecureStorage().write(key: 'token', value: session.token);
      return session;
    });
    if (state case AsyncError(:final error, :final stackTrace)) {
      ref.read(loggerProvider).e('Register failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> logout() async {
    final api = ref.read(apiClientProvider);
    api.token = null;
    await const FlutterSecureStorage().delete(key: 'token');
    state = const AsyncData(null);
  }
}
