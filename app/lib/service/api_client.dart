import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openpayments_app/service/logger_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final http.Client _client;
  final String baseURL;
  final AppLogger? _logger;
  String? _token;

  ApiClient({
    required this.baseURL,
    AppLogger? logger,
    http.Client? client,
  }) : _client = client ?? http.Client(),
       // ignore: prefer_initializing_formals
       _logger = logger;

  set token(String? value) => _token = value;
  String? get token => _token;
  String get baseUrl => baseURL;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static const _timeout = Duration(seconds: 15);

  Future<dynamic> get(String path) async {
    final uri = Uri.parse('$baseURL$path');
    _logger?.d('GET $uri');
    final response = await _client.get(uri, headers: _headers).timeout(_timeout);
    return _handle(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseURL$path');
    _logger?.d('POST $uri');
    final response = await _client
        .post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
        .timeout(_timeout);
    return _handle(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseURL$path');
    _logger?.d('PUT $uri');
    final response = await _client
        .put(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
        .timeout(_timeout);
    return _handle(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseURL$path');
    _logger?.d('PATCH $uri');
    final response = await _client
        .patch(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
        .timeout(_timeout);
    return _handle(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseURL$path');
    _logger?.d('DELETE $uri');
    final response = await _client.delete(uri, headers: _headers).timeout(_timeout);
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _logger?.d('${response.statusCode} ${response.request?.url}');
      return body;
    }

    final message = body is Map
        ? (body['error'] as String? ?? 'Unknown error')
        : 'Unknown error';

    _logger?.e(
      'API ${response.statusCode}: $message',
      error: ApiException(response.statusCode, message),
    );

    throw ApiException(response.statusCode, message);
  }
}
