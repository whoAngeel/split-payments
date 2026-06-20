import 'package:openpayments_app/models/session.dart';
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

  Future<Session> register(String email, String password, String name) async {
    final json = await _api.post(
      '/api/auth/register',
      body: {'email': email, "password": password, 'name': name},
    );
    _logger.i('register');
    return Session.fromJson(json as Map<String, dynamic>);
  }
}
