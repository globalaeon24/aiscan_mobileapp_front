import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import '../main.dart';
import 'auth_service.dart';
import 'security_service.dart';

class ApiService {
  static const baseUrl = ApiConfig.baseUrl;
  static Future<bool>? _refreshFuture;

  /// 🔓 Публичные эндпоинты (НЕ ТРОГАЕМ logout)
  static const List<String> _publicPaths = [
    '/auth/login',
  ];

  // ===================== GET =====================
  static Future<http.Response> get(String path) async {
    return _send(
      path,
      () async {
        final token = await TokenStorage.getToken();
        return http.get(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        );
      },
    );
  }

  // ===================== POST =====================
  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _send(
      path,
      () async {
        final token = await TokenStorage.getToken();
        return http.post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          body: body == null ? null : jsonEncode(body),
        );
      },
    );
  }

  static Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _send(
      path,
      () async {
        final token = await TokenStorage.getToken();
        return http.patch(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          body: body == null ? null : jsonEncode(body),
        );
      },
    );
  }

  static Future<http.Response> delete(String path) async {
    return _send(
      path,
      () async {
        final token = await TokenStorage.getToken();
        return http.delete(
          Uri.parse('$baseUrl$path'),
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        );
      },
    );
  }

  static Future<http.StreamedResponse> sendMultipart(
    Future<http.MultipartRequest> Function(String token) buildRequest,
  ) async {
    Future<http.StreamedResponse> send() async {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Нет токена авторизации.');
      }
      return (await buildRequest(token)).send();
    }

    var response = await send();
    if (response.statusCode != 401) return response;

    await response.stream.drain<void>();
    if (await _refreshSessionOnce()) {
      response = await send();
      if (response.statusCode != 401) return response;
    }
    await _forceLogout();
    return response;
  }

  // ===================== CORE =====================
  static Future<http.Response> _send(
    String path,
    Future<http.Response> Function() request,
  ) async {
    var response = await request();

    if (response.statusCode == 401 && !_isPublic(path)) {
      if (await _refreshSessionOnce()) {
        response = await request();
      }
      if (response.statusCode == 401) await _forceLogout();
    }

    return response;
  }

  static bool _isPublic(String path) {
    return _publicPaths.any((p) => path.startsWith(p));
  }

  static Future<bool> refreshSessionOrLogout() async {
    final refreshed = await _refreshSessionOnce();
    if (!refreshed) await _forceLogout();
    return refreshed;
  }

  static Future<bool> _refreshSessionOnce() async {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null) return activeRefresh;

    final refresh = AuthService.refreshSession();
    _refreshFuture = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshFuture, refresh)) _refreshFuture = null;
    }
  }

  // ===================== LOGOUT =====================
  static Future<void> _forceLogout() async {
    await TokenStorage.clear();
    await SecurityService.clear();

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}
