import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';

  static String? accessToken;
  static String? refreshToken;
  static String? username;
  static final ValueNotifier<bool> authenticationState = ValueNotifier(false);

  static Future<bool>? _refreshInProgress;

  static Future<bool> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_accessTokenKey);
    refreshToken = prefs.getString(_refreshTokenKey);
    username = prefs.getString(_usernameKey);

    if (accessToken == null || refreshToken == null) {
      await _clearSession();
      return false;
    }

    if (_isTokenExpired(accessToken!)) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        await _clearSession();
        return false;
      }
    }

    authenticationState.value = true;
    return true;
  }

  static Future<void> register({
    required String username,
    String? email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register/');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username.trim(),
            'email': email?.trim() ?? '',
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final errors = <String>[];
        body.forEach((key, value) {
          if (value is List) {
            errors.addAll(value.map((item) => item.toString()));
          } else {
            errors.add(value.toString());
          }
        });
        throw Exception(errors.join(' '));
      }
      throw Exception('Registration failed.');
    }
  }

  static Future<void> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login/');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final message = body is Map<String, dynamic>
          ? body['detail'] ?? body['message'] ?? 'Invalid credentials.'
          : 'Invalid credentials.';
      throw Exception(message);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    accessToken = json['access'] as String?;
    refreshToken = json['refresh'] as String?;
    AuthService.username = username.trim();

    if (accessToken == null || refreshToken == null) {
      throw Exception('Missing authentication tokens.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken!);
    await prefs.setString(_refreshTokenKey, refreshToken!);
    await prefs.setString(_usernameKey, AuthService.username!);
    authenticationState.value = true;
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    if (accessToken == null) {
      await initialize();
    }

    if (accessToken == null ||
        (_isTokenExpired(accessToken!) && !await _refreshAccessToken())) {
      await _clearSession();
      throw Exception('Your session has expired. Please sign in again.');
    }

    return {'Authorization': 'Bearer $accessToken'};
  }

  static Future<void> logout() async {
    await _clearSession();
  }

  static Future<void> _clearSession() async {
    accessToken = null;
    refreshToken = null;
    username = null;
    authenticationState.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_usernameKey);
  }

  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final expiry = payload is Map<String, dynamic> ? payload['exp'] : null;
      if (expiry is! num) return true;

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expiry.toInt() * 1000,
        isUtc: true,
      );
      return DateTime.now()
          .toUtc()
          .add(const Duration(seconds: 30))
          .isAfter(expiresAt);
    } catch (_) {
      return true;
    }
  }

  static Future<bool> _refreshAccessToken() {
    return _refreshInProgress ??= _performRefresh().whenComplete(() {
      _refreshInProgress = null;
    });
  }

  static Future<bool> _performRefresh() async {
    final token = refreshToken;
    if (token == null || _isTokenExpired(token)) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': token}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return false;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || body['access'] is! String) {
        return false;
      }

      accessToken = body['access'] as String;
      if (body['refresh'] is String) {
        refreshToken = body['refresh'] as String;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken!);
      await prefs.setString(_refreshTokenKey, refreshToken!);
      authenticationState.value = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<http.Response> authenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) async {
    var response = await send(await getAuthHeaders());
    if (response.statusCode != 401) return response;

    if (!await _refreshAccessToken()) {
      await _clearSession();
      throw Exception('Your session has expired. Please sign in again.');
    }

    response = await send(await getAuthHeaders());
    if (response.statusCode == 401) {
      await _clearSession();
      throw Exception('Your session has expired. Please sign in again.');
    }
    return response;
  }

  static Future<Map<String, dynamic>> fetchProfile() async {
    final uri = Uri.parse('$baseUrl/auth/me/');
    final response = await authenticatedRequest((authHeaders) {
      return http
          .get(uri, headers: authHeaders)
          .timeout(const Duration(seconds: 10));
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> updateProfile({
    required String username,
    String? email,
    String? password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/me/');
    final payload = {'username': username.trim(), 'email': email?.trim() ?? ''};
    if (password != null && password.isNotEmpty) {
      payload['password'] = password;
    }

    final response = await authenticatedRequest((authHeaders) {
      return http
          .put(
            uri,
            headers: {...authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
    });

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final errors = <String>[];
        body.forEach((key, value) {
          if (value is List) {
            errors.addAll(value.map((item) => item.toString()));
          } else {
            errors.add(value.toString());
          }
        });
        throw Exception(errors.join(' '));
      }
      throw Exception('Failed to update profile.');
    }

    if (AuthService.username != username.trim()) {
      AuthService.username = username.trim();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usernameKey, AuthService.username!);
    }
  }

  static bool get isSignedIn => authenticationState.value;
}
