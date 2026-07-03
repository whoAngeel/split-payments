import 'package:openpayments_app/models/session.dart';
import 'package:openpayments_app/models/user.dart';
import 'package:openpayments_app/service/api_client.dart';
import 'package:openpayments_app/service/logger_service.dart';

class AuthService {
  final ApiClient _api;
  final AppLogger _logger;
  AuthService(this._api, this._logger);

  Future<Session> login(String email, String password) async {
    _logger.i('Attempting login for $email');
    final json = await _api.post(
      '/api/auth/login',
      body: {'email': email, "password": password},
    );
    _logger.i('Login success');
    return Session.fromJson(json as Map<String, dynamic>);
  }

  Future<Session> register(String email, String password, String name, {String? walletAddress}) async {
    final normalizedWallet = _normalizeWallet(walletAddress);
    final json = await _api.post(
      '/api/auth/register',
      body: {
        'email': email,
        'password': password,
        'name': name,
        'role': 'buyer',
        if (normalizedWallet != null) 'wallet_address_url': normalizedWallet,
      },
    );
    _logger.i('register');
    return Session.fromJson(json as Map<String, dynamic>);
  }

  Future<Session> me(String token) async {
    final json = await _api.get('/api/auth/me');
    final data = json as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    return Session(
      token: token,
      user: user,
      galleryId: (data['gallery_id'] as num?)?.toInt() ?? 0,
    );
  }

  Future<User> updateMe({String? name, String? walletAddressUrl}) async {
    final json = await _api.patch(
      '/api/auth/me',
      body: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (walletAddressUrl != null) 'wallet_address_url': walletAddressUrl,
      },
    );
    return User.fromJson(json as Map<String, dynamic>);
  }

  String? _normalizeWallet(String? wallet) {
    if (wallet == null || wallet.trim().isEmpty) return null;
    final w = wallet.trim();
    if (w.startsWith(r'$')) return 'https://${w.substring(1)}';
    return w;
  }
}
